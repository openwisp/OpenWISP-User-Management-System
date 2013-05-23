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

  def self.get(key, default=false)
    # get key method, can provide default value
    res = Configuration.find_by_key(key)
    # neither result and neither a default value return nil
    if res.nil? and not default
      nil
    # no result but default value return default
    elsif res.nil?
      default
    # return value
    else
      res.value
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
  
  def invalidate_cache
    Rails.cache.delete("owums_settings")
  end
end
