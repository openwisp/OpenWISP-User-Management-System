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

class Operator < ActiveRecord::Base
  
  ROLES = %w(users_destroyer users_manager users_registrant stats_viewer users_finder users_browser)

  acts_as_authentic
  acts_as_authorization_subject
  acts_as_authorization_object :subject_class_name => 'Operator'

  # Access current_operator from models
  cattr_accessor :current_operator

  def initialize(params = nil)
    super(params)
    
  end
  
  def roles
    @rs = []
    Operator::ROLES.each do |r|
      @rs << r if self.has_role?(r)
    end
    @rs
  end

end
