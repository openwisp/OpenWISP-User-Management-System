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

class RemoveTimestampsFromOperatorsRoles < ActiveRecord::Migration
  ### Removed because:
  # Having additional attributes on the join table of a
  # has_and_belongs_to_many association is deprecated and
  # will be removed in Rails 3.1.
  # Please use a has_many :through association instead.

  def self.up
    remove_column :operators_roles, :created_at
    remove_column :operators_roles, :updated_at
  end

  def self.down
    add_column :operators_roles, :created_at, :datetime
    add_column :operators_roles, :updated_at, :datetime
  end
end
