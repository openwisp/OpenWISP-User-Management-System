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

class OperatorSessionsController < ApplicationController
  before_filter :require_no_operator, :only => [:new, :create]
  before_filter :require_operator, :only => :destroy
  
  def new
    @operator_session = OperatorSession.new
  end
  
  def create
    @operator_session = OperatorSession.new(params[:operator_session])
    if @operator_session.save
      flash[:notice] = I18n.t(:Login_successful)
      #Avoids session fixations
      reset_session
      if @operator_session.record.has_role? 'stats_viewer'
        redirect_to users_url
      elsif @operator_session.record.has_role? 'users_registrant'
        redirect_to new_user_url
      elsif @operator_session.record.has_role? 'users_browser'
        redirect_to users_browse_url
      elsif @operator_session.record.has_role? 'users_finder'
        redirect_to users_search_url
      elsif @operator_session.record.has_role? 'operators_manager'
        redirect_to operators_url
      else # "Uh? Error!"
        redirect_back_or_default users_url
      end
    else
      render :action => :new
    end
  end
  
  def destroy
    current_operator_session.destroy
    flash[:notice] = I18n.t(:Logout_successful)
    redirect_back_or_default operator_login_url
  end
end
