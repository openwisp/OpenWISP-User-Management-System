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

class MobilePhonePasswordResetsController < ApplicationController
  before_filter :load_account_using_perishable_token, :only => [ :edit, :update ]
  before_filter :load_account_using_single_access_token, :only => [ :verification, :recovery_confirmation ]
  before_filter :require_no_account
  
  def new
    @mobile_prefixes = MobilePrefix.all

    respond_to do |format|
      format.html
      format.mobile
      format.xml { render_if_xml_restful_enabled }
    end
  end
  
  def create
    @mobile_prefixes = MobilePrefix.all
    if params[:mobile_phone_password_reset]
      @account = Account.find_by_mobile_suffix(params[:mobile_phone_password_reset][:mobile_suffix], 
      :conditions => ["mobile_prefix = ?", params[:mobile_phone_password_reset][:mobile_prefix]])
    end

    if @account
      @account.ask_for_mobile_phone_password_recovery!
      @single_access_token = @account.single_access_token

      respond_to do |format|
        format.html { render :action => :verification }
        format.mobile { render :action => :verification }
        format.xml { render_if_xml_restful_enabled :action => :verification, :status => :created }
      end
    else
      @mobile_prefixes = MobilePrefix.all
      flash[:notice] = I18n.t(:No_user_found_with_that_mobile_phone)

      respond_to do |format|
        format.html { render :action => :new }
        format.mobile { render :action => :new }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    if @account.recovered?
      respond_to do |format|
        format.html
        format.mobile
        format.xml
      end
    else
      respond_to do |format|
        format.html { render "common/abuse", :layout => false }
        format.mobile { render "common/abuse", :layout => false }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :forbidden }
      end
    end
  end
 
  def update
    @account.password = params[:account][:password]
    @account.password_confirmation = params[:account][:password_confirmation]
    password_changed = @account.changed?

    if password_changed and @account.save_from_mobile_phone_password_recovery
      flash[:notice] = I18n.t(:Password_successfully_updated)

      respond_to do |format|
        format.html { redirect_to root_url }
        format.mobile { redirect_to root_url }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :accepted }
      end
    else
      flash[:notice] = I18n.t(:Password_not_successfully_updated) unless password_changed

      respond_to do |format|
        format.html   { render :action => :edit }
        format.mobile { render :action => :edit }
        format.xml { render_if_xml_restful_enabled :xml => @account.errors, :status => :unprocessable_entity }
      end
    end
  end

  def recovery_confirmation
    if @account.recovered?
      render
    else
      @single_access_token = @account.single_access_token
      respond_to do |format|
        format.html { render :action => :verification }
        format.mobile { render :action => :verification }
        format.xml { render_if_xml_restful_enabled }
      end
    end
  end

  def verification
    respond_to do |format|
      if request.xhr? # Ajax request
        format.html   { render :partial => 'verification' }
        format.mobile { render :partial => 'verification' }
      else
        @single_access_token = @account.single_access_token
        format.html
        format.mobile
      end
    end
  end

  private
    def load_account_using_perishable_token
      @account = Account.find_using_perishable_token(params[:id])
      unless @account
        #flash[:notice] = I18n.t(:Perishable_token_error)
        respond_to do |format|
          format.html { redirect_to root_url }
          format.mobile { redirect_to root_url }
          format.xml { render_if_xml_restful_enabled :nothing => true, :status => :forbidden }
        end
      end
    end

    def load_account_using_single_access_token
      @account = Account.find_by_single_access_token(params[:id])
      unless @account
        #flash[:notice] = I18n.t(:Perishable_token_error)
        respond_to do |format|
          format.html { redirect_to root_url }
          format.mobile { redirect_to root_url }
          format.xml { render_if_xml_restful_enabled :nothing => true, :status => :forbidden }
        end
      end
    end

end
