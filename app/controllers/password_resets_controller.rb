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

class PasswordResetsController < ApplicationController

  def new
    @recovery_methods = %w(mobile_phone email)
    render
  end
  
  def create
    @recovery_methods = %w(mobile_phone email)
    case params[:recovery_method]
    when 'email'
      redirect_to :controller => :email_password_resets, :action => :new
    when'mobile_phone'
      redirect_to :controller => :mobile_phone_password_resets, :action => :new
    else
      render 'common/abuse'
    end
  end
  
end
