# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Configuration < ActiveRecord::Base

  validates_presence_of :key
  validates_format_of :key, :with => /\A[a-z_\.,]+\Z/

  attr_accessible :key, :value, :system_key
  
  after_save :invalidate_cache
  after_create :invalidate_cache
  after_destroy :invalidate_cache
  
  @@cache = nil
  
  def self.cache
    cache_key = "owums_settings"
    
    if @@cache.nil?
      # retrieve settings from cache if present
      @@cache = Rails.cache.fetch(cache_key)
    end
    
    # otherwise retrieve from database and create the hash we will cache
    if @@cache.nil?
      @@cache = {}
      
      Configuration.all.each do |config|
        @@cache[config.key.to_sym] = config.value
      end
      
      Rails.cache.write(cache_key, @@cache)
    end
    
    @@cache
  end
  
  def invalidate_cache
    @@cache = nil
    Rails.cache.delete("owums_settings")
  end

  def self.get(key, default=false)
    # load from DB if necessary
    if @@cache.nil?
      self.cache()
    end
    
    # return from cache
    unless @@cache[key.to_sym].nil?
      return @@cache[key.to_sym]
    # otherwise try retrieving from DB
    else
      # get key method, can provide default value
      res = Configuration.find_by_key(key)
      # neither result and neither a default value return nil
      if res.nil? and not default
        nil
      # no result but default value return default
      elsif res.nil?
        default
      # if found a result, update the cache and return the value
      else
        res.invalidate_cache
        res.value
      end
    end
  end

  def self.set(key, value)
    if prev = Configuration.find_by_key(key)
      prev.set(value)
    else
      Configuration.new(:key => key, :value => value).save!
    end
  end

  def set(value = '')
    self.system_key? && raise("BUG: key " + key + "is readonly!")
    self.value = value
    self.save!
  end
  
  def system_key?
    self.system_key
  end
end
