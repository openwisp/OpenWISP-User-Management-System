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

class AddMoreIndexes < ActiveRecord::Migration
  def self.up
    add_index :mobile_prefixes, :disabled
    add_index :mobile_prefixes, :prefix
    add_index :countries, :disabled
    add_index :users, :email
    add_index :users, :single_access_token
    add_index :users, :perishable_token
    add_index :users, :updated_at
  end

  def self.down
    remove_index :mobile_prefixes, :disabled
    remove_index :mobile_prefixes, :prefix
    remove_index :countries, :disabled
    remove_index :users, :email
    remove_index :users, :single_access_token
    remove_index :users, :perishable_token
    remove_index :users, :updated_at
  end
end
