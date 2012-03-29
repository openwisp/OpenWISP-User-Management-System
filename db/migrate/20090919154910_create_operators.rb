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

class CreateOperators < ActiveRecord::Migration
  def self.up
    create_table :operators do |t|
      t.timestamps
      
      t.string   :login,              :null => false
      t.string   :crypted_password,   :null => false
      t.string   :password_salt,      :null => false
      t.string   :persistence_token,  :null => false
      t.integer  :login_count,        :null => false, :default => 0
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      t.string   :last_login_ip
      t.string   :current_login_ip
      
      t.text     :notes

    end
    
    add_index :operators, :login
    add_index :operators, :persistence_token
    add_index :operators, :last_request_at
    
  end

  def self.down
    drop_table :operators
  end
end
