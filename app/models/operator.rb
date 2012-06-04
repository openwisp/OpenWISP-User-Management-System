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

class Operator < ActiveRecord::Base
  
  ROLES = %w(
    users_destroyer users_manager users_registrant registrant_by_nothing registrant_by_id_card
    stats_viewer users_finder users_browser configurations_manager
    operators_manager
    radius_groups_creator radius_groups_viewer radius_groups_manager radius_groups_destroyer
    radius_checks_creator radius_checks_viewer radius_checks_manager radius_checks_destroyer
    radius_replies_creator radius_replies_viewer radius_replies_manager radius_replies_destroyer
  )

  SINGLE_OBJECT_ROLES = %w(
    user_manager
  )

  acts_as_authentic do |c|
    c.merge_validates_length_of_password_field_options( { :minimum => 8 } )
    c.validates_length_of_login_field_options = { :in => 4..16 }
    c.validates_format_of_login_field_options = { :with => /\A[a-z0-9_\-\.]+\Z/i }
    c.session_class = OperatorSession
    c.maintain_sessions = false
  end

  acts_as_authorization_subject
  acts_as_authorization_object :subject_class_name => 'Operator'

  # Validations
  # # Allowing nil to avoid duplicate error notification (password field is already validated by Authlogic)
  validates_format_of :password, :with => /\A.*([a-z][0-9])|([0-9][a-z]).*\Z/i, :message => :password_format,
                      :allow_nil => true

  attr_readonly :login

  attr_accessible :login, :password, :password_confirmation, :notes, :roles

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

  def roles=(new_roles)
    to_remove = self.roles - new_roles
    new_roles.each{|role| self.has_role! role if Operator::ROLES.include? role}
    to_remove.each{|role| self.has_no_role! role}
  end
end
