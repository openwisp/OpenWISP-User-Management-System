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

class EmailPasswordResetsController < ApplicationController
  before_filter :load_account_using_perishable_token, :only => [:edit, :update]
  before_filter :require_no_account
  
  def new
  end
  
  def create
    @account = Account.find_by_email(params[:email_password_reset][:email]) if params[:email_password_reset]
    if @account
      @account.deliver_password_reset_instructions!
      flash[:notice] = I18n.t(:Instruction_reset_has_been_mailed)
      redirect_to root_url
    else
      flash[:notice] = I18n.t(:No_user_found_with_that_email)
      render :action => :new
    end
  end
  
  def edit
  end
 
  def update
    @account.password = params[:account][:password]
    @account.password_confirmation = params[:account][:password_confirmation]
    if @account.save_without_session_maintenance
      flash[:notice] = I18n.t(:Password_successfully_updated)
      redirect_to root_url
    else
      render :action => :edit
    end
  end

  private
    def load_account_using_perishable_token
      @account = Account.find_using_perishable_token(params[:id])
      unless @account
        flash[:notice] = I18n.t(:Perishable_token_error)
        redirect_to root_url
      end
    end
end
