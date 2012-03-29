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

class CreateMobilePrefixes < ActiveRecord::Migration
  def self.up
    create_table :mobile_prefixes do |t|
      t.integer :prefix,                :null => false
      t.integer :international_prefix,  :null => true
      t.boolean :disabled,              :null => false, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :mobile_prefixes
  end
end
