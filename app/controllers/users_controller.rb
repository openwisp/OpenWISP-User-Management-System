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

class UsersController < ApplicationController
  before_filter :require_operator
  before_filter :load_user, :except => [:index, :new, :create, :search, :find]
  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :users_browser, :to => [:index, :show]
    allow :users_registrant, :to => [:new, :create]
    allow :users_manager, :to => [:new, :create, :edit, :update]
    allow :users_destroyer, :to => [:destroy]
    allow :users_finder, :to => [:find, :search, :show]
  end

  STATS_PERIOD = 14

  def index
    sort_and_paginate_users

    respond_to do |format|
      format.html
      format.js
      format.xml { render :xml => @users }
    end
  end

  def new
    @user = User.new(:eula_acceptance => true, :privacy_acceptance => true, :state => 'Italy', :verification_method => User.verification_methods.first)
    @user.verified = true
    @user.radius_groups = [RadiusGroup.find_by_name!(Configuration.get(:default_radius_group))]

    @countries = Country.all
    @mobile_prefixes = MobilePrefix.all
    @radius_groups = RadiusGroup.all
  end

  def create
    params[:user][:radius_group_ids].uniq! if params[:user] && params[:user][:radius_group_ids]
    @user = User.new(params[:user])

    # Parameter anti-tampering
    unless current_operator.has_role? 'users_manager'
      @user.radius_groups = [RadiusGroup.find_by_name!(Configuration.get(:default_radius_group))]
      @user.verified = @user.active = true
    end

    @countries = Country.all
    @mobile_prefixes = MobilePrefix.all
    @radius_groups = RadiusGroup.all

    if @user.save
      current_account_session.destroy unless current_account_session.nil?

      # Associate user with the operator the current operator
      current_operator.has_role!('user_manager', @user)

      respond_to do |format|
        format.html { render :ticket }
        format.xml { render :xml => @user, :status => :created }
      end
    else
      respond_to do |format|
        format.html { render :action => :new }
        format.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    if request.format.html? || request.format.js?
      sort_and_paginate_accountings
    end

    respond_to do |format|
      format.html
      format.js
      format.jpg
      format.xml { render :xml => @user }
    end

  end

  def edit
    @countries = Country.all
    @mobile_prefixes = MobilePrefix.all
    @radius_groups = RadiusGroup.all
  end

  def update
    # Parameter anti-tampering
    params[:user][:radius_group_ids] = nil unless current_operator.has_role? 'users_manager'
    params[:user][:radius_group_ids].uniq! if params[:user] && params[:user][:radius_group_ids]

    @countries = Country.all
    @mobile_prefixes = MobilePrefix.all
    @radius_groups = RadiusGroup.all

    if @user.update_attributes(params[:user])
      current_account_session.destroy unless current_account_session.nil?
      flash[:notice] = I18n.t(:Account_updated)

      respond_to do |format|
        format.html { redirect_to user_url }
        format.xml { render :nothing => true, :status => :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => :edit }
        format.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.xml { render :nothing => true, :status => :ok }
    end
  end

  def find
    if params[:user] && params[:user][:query]
      query = params[:user][:query]
      found_users = User.find_all_by_user_phone_or_mail(query)

      if found_users.count == 1
        @user = found_users.first
        respond_to do |format|
          format.html { redirect_to user_url(@user) }
          format.xml { render :xml => @user }
          end
      elsif found_users.count > 1
        flash[:error] = I18n.t(:Too_many_search_results)
        respond_to do |format|
          format.html { render :action => :search }
          format.xml { render :nothing => true, :status => :unprocessable_entity }
        end
      else
        flash[:error] = I18n.t(:User_not_found)
        respond_to do |format|
          format.html { render :action => :search }
          format.xml { render :nothing => true, :status => :not_found }
        end
      end
    else
      flash[:error] = I18n.t(:User_not_found)
      respond_to do |format|
        format.html { render :action => :search }
        format.xml { render :nothing => true, :status => :bad_request }
      end
    end
  end

  private

  def load_user
    @user = User.find_by_id_or_username!(params[:id])
  end

  def sort_and_paginate_accountings
    items_per_page = Configuration.get('default_radacct_results_per_page')

    sort = case params[:sort]
             when 'acct_start_time' then
               "AcctStartTime"
             when 'acct_stop_time' then
               "AcctStopTime"
             when 'acct_input_octets' then
               "AcctInputOctets"
             when 'acct_output_octets' then
               "AcctOutputOctets"
             when 'calling_station_id' then
               "CallingStationId"
             when 'framed_ip_address' then
               "FramedIPAddress"
             when 'acct_start_time_rev' then
               "AcctStartTime DESC"
             when 'acct_stop_time_rev' then
               "AcctStopTime DESC"
             when 'acct_input_octets_rev' then
               "AcctInputOctets DESC"
             when 'acct_output_octets_rev' then
               "AcctOutputOctets DESC"
             when 'calling_station_id_rev' then
               "CallingStationId DESC"
             when 'framed_ip_address_rev' then
               "FramedIPAddress DESC"
             else
               nil
           end
    if sort.nil?
      params[:sort] = "acct_start_time_rev"
      sort = "AcctStartTime DESC"
    end

    page = params[:page].nil? ? 1 : params[:page]

    @total_accountings = @user.radius_accountings.count
    @radius_accountings = @user.radius_accountings.order(sort).page(page).per(items_per_page)
  end

  def sort_and_paginate_users
    items_per_page = Configuration.get('default_user_search_results_per_page')

    sort = case params[:sort]
             when 'registered_at' then
               "created_at"
             when 'username' then
               "username"
             when 'given_name' then
               "given_name"
             when 'surname' then
               "surname"
             when 'state' then
               "state"
             when 'city' then
               "city"
             when 'address' then
               "address"
             when 'verified' then
               "verified"
             when 'active' then
               "active"
             when 'registered_at_rev' then
               "created_at DESC"
             when 'username_rev' then
               "username DESC"
             when 'given_name_rev' then
               "given_name DESC"
             when 'surname_rev' then
               "surname DESC"
             when 'state_rev' then
               "state DESC"
             when 'city_rev' then
               "city DESC"
             when 'address_rev' then
               "address DESC"
             when 'verified_rev' then
               "verified DESC"
             when 'active_rev' then
               "active DESC"
             else
               nil
           end
    if sort.nil?
      params[:sort] = "registered_at_rev"
      sort = "created_at DESC"
    end
    
    enabled = params[:enabled] == '' ? nil : params[:enabled]
    verified = params[:verified] == '' ? nil : params[:verified]
    verification_method = params[:verification_method] == 'all' ? nil : params[:verification_method]
    
    sql = "1=1 "
    bind_params = []
    
    unless enabled.nil?
      sql << "AND active = ? "
      bind_params += [
        (enabled == 'true' ? 1 : 0) 
      ]
    end
    
    unless verified.nil?
      sql << "AND verified = ? "
      bind_params += [
        (verified == 'true' ? 1 : 0) 
      ]
    end
    
    unless verification_method.nil?
      sql << "AND verification_method = ? "
      bind_params += [verification_method]
    end

    search = params[:search]
    page = params[:page].nil? ? 1 : params[:page]

    unless search.nil?
      search.gsub(/\\/, '\&\&').gsub(/'/, "''")
      sql <<  "AND (given_name LIKE ? OR surname LIKE ? OR username LIKE ? OR email LIKE ? OR CONCAT(mobile_prefix,mobile_suffix)" +
              "LIKE ? OR CONCAT_WS(' ', given_name, surname) LIKE ? OR CONCAT_WS(' ', surname, given_name) LIKE ?)"
      bind_params += [
        "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%"
      ]
    end
    
    conditions = [sql] + bind_params

    @total_users = User.count :conditions => conditions
    @users = User.where(conditions).order(sort).page(page).per(items_per_page)
  end
end
