# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
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

class AccountSessionsController < ApplicationController
  before_filter :require_no_account, :only => [:new, :create]
  before_filter :require_account, :only => :destroy

  def new
    @account_session = AccountSession.new

    respond_to do |format|
      format.html
      format.mobile
      format.xml { render_if_xml_restful_enabled }
    end
  end

  def create
    @account_session = AccountSession.new(params[:account_session])
    if @account_session.save
      flash[:notice] = I18n.t(:Login_successful)
      #Avoids session fixations
      keep_session_data :locale do
        reset_session
      end

      respond_to do |format|
        format.html { redirect_to account_url }
        format.mobile { redirect_to account_url }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :created }
      end
    else
      respond_to do |format|
        format.html   { render :action => :new }
        format.mobile { render :action => :new }
        format.xml    { render_if_xml_restful_enabled :xml => @account_session.errors, :status => :unauthorized }
      end
    end
  end

  def destroy
    current_account_session.destroy
    flash[:notice] = I18n.t(:Logout_successful)
    respond_to do |format|
      format.html { redirect_to root_path }
      format.mobile { redirect_to root_path }
      format.xml { render_if_xml_restful_enabled :nothing => true }
    end

  end
end
