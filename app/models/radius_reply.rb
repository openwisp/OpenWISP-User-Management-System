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

class RadiusReply < ActiveRecord::Base
  validates_presence_of :reply_attribute
  validates_uniqueness_of :reply_attribute, :scope => [ :radius_entity_id, :radius_entity_type ]
  validates_presence_of :op
  validates_inclusion_of :op, :in => %w(= := +=)
  validates_presence_of :value

  belongs_to :radius_entity, :polymorphic => true

  attr_accessible :reply_attribute, :op, :value, :radius_entity

end
