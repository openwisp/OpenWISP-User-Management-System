# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2010 CASPUR (Davide Guerri d.guerri@caspur.it)
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

class RadiusGroup < ActiveRecord::Base
  validates_uniqueness_of :name

  has_and_belongs_to_many :account_commons, :join_table => 'radius_groups_users' 
  has_many :radius_checks, :as => :radius_entity, :dependent => :destroy
  has_many :radius_replies, :as => :radius_entity, :dependent => :destroy

  def radius_name
    name
  end

  def self.users_group
    find_by_name("Users").id
  end

  def self.disabled_users_group
    find_by_name("Disabled").id
  end

  def self.power_users_group
    find_by_name("PowerUsers").id
  end

  def self.machines_group
    find_by_name("Machines").id
  end
  
end
