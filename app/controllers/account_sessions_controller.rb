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

class AccountSessionsController < ApplicationController
  before_filter :require_no_account, :only => [:new, :create]
  before_filter :require_account, :only => :destroy
  
  def new
    @account_session = AccountSession.new
    
    respond_to do |format|
      format.html
      format.mobile
    end
  end
  
  def create
    @account_session = AccountSession.new(params[:account_session])
    if @account_session.save
      flash[:notice] = I18n.t(:Login_successful)
      #Avoids session fixations
      reset_session
      redirect_to account_url
    else
      respond_to do |format|
        format.html   { render :action => :new }
        format.mobile { render :action => :new }
     end
    end
  end
  
  def destroy
    current_account_session.destroy
    flash[:notice] = I18n.t(:Logout_successful)
    redirect_to root_path
  end
end
