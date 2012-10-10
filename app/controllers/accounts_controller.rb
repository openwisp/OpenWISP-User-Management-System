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

class AccountsController < ApplicationController
  before_filter :require_account, :only => [
      :show, :edit, :update
  ]

  before_filter :require_no_account, :only => [
      :new, :create, :verify_credit_card, :secure_verify_credit_card
  ]

  before_filter :require_no_operator

  before_filter :load_account, :except => [ :new, :create ]

  protect_from_forgery :except => [ :verify_credit_card, :secure_verify_credit_card ]

  STATS_PERIOD = 14

  def new
    @account = Account.new( :verification_method => Account::VERIFY_BY_MOBILE, :state => 'Italy' )
    @countries = Country.all
    @mobile_prefixes = MobilePrefix.all

    respond_to do |format|
      format.html
      format.mobile
      format.xml { render_if_xml_restful_enabled }
    end
  end

  def create
    @account = Account.new(params[:account])
    @countries = Country.all
    @mobile_prefixes = MobilePrefix.all

    @account.radius_groups << RadiusGroup.find_by_name!(Configuration.get('default_radius_group'))

    @account.captcha_verification = session[:captcha]

    save_account = request.format.xml? ? @account.save : @account.save_with_captcha

    if save_account
      respond_to do |format|
        format.html { redirect_to account_path }
        format.mobile { redirect_to account_path }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :created }
      end
    else
      respond_to do |format|
        format.html   { render :action => :new }
        format.mobile { render :action => :new }
        format.xml { render_if_xml_restful_enabled :xml => @account.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    if not User.self_verification_methods.include?(@account.verification_method) and !@account.verified?
      respond_to do |format|
        format.html   { render :action => :no_verification }
        format.mobile { render :action => :no_verification }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :forbidden }
      end
    elsif @current_operator.nil? and !@account.verified?
      respond_to do |format|
        format.html   { render :action => :verification }
        format.mobile { render :action => :verification }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :forbidden }
      end
    else
      sort_and_paginate_accountings unless request.format.jpg?
      
      respond_to do |format|
        format.html
        format.mobile
        format.xml { render_if_xml_restful_enabled }
        format.jpg
        format.js
      end
    end
  end

  def edit
    if not User.self_verification_methods.include?(@account.verification_method) and !@account.verified?
      respond_to do |format|
        format.html   { render :action => :no_verification }
        format.mobile { render :action => :no_verification }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :forbidden }
      end
    elsif @current_operator.nil? and !@account.verified?
      respond_to do |format|
        format.html   { render :action => :verification }
        format.mobile { render :action => :verification }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :forbidden }
      end
    else
      @countries = Country.all
      @mobile_prefixes = MobilePrefix.all
      respond_to do |format|
        format.html
        format.mobile
        format.xml { render_if_xml_restful_enabled }
      end
    end
  end

  def update
    if !@current_operator.nil? or !@account.verified?
      respond_to do |format|
        format.html   { render :action => :verification }
        format.mobile { render :action => :verification }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :forbidden }
      end
    else
      @countries = Country.all
      @mobile_prefixes = MobilePrefix.all

      to_disable = false

      if params[:account][:disable_account]
        to_disable = true
        params[:account].delete :disable_account
        @account.verified = false
      end

      if @account.update_attributes(params[:account])
        if to_disable
          flash[:notice] = I18n.t(:Account_disabled)
          current_account_session.destroy

          respond_to do |format|
            format.html { redirect_to :root }
            format.mobile { redirect_to :root }
            format.xml { render_if_xml_restful_enabled :nothing => true, :status => :accepted }
          end
        else
          flash[:notice] = I18n.t(:Account_updated)

          respond_to do |format|
            format.html { redirect_to account_url }
            format.mobile { redirect_to account_url }
            format.xml { render_if_xml_restful_enabled :nothing => true, :status => :accepted }
          end
        end
      else
        respond_to do |format|
          format.html   { render :action => :edit }
          format.mobile { render :action => :edit }
          format.xml { render_if_xml_restful_enabled :xml => @account.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def verification
    if @account.nil? # Account expired (and removed by the housekeeping backgroundrb job)
      respond_to do |format|
        if request.xhr? # Ajax request
          format.html   { render :partial => 'expired' }
          format.mobile { render :partial => 'expired' }
        else
          format.html   { render :action => 'expired' }
          format.mobile { render :action => 'expired' }
          format.xml { render_if_xml_restful_enabled :nothing => true, :status => :request_timeout }
        end
      end
    else
      respond_to do |format|
        if request.xhr? # Ajax request
          format.html   { render :partial => 'verification' }
          format.mobile { render :partial => 'verification' }
        else
          format.html   { render :action => 'verification' }
          format.mobile { render :action => 'verification' }
          format.xml { render_if_xml_restful_enabled }
        end
      end
    end
  end

  def verify_credit_card
    # Method to be called by paypal (IPN) to
    # verify user. Invoice is the account's id.
    # I know this method is verbose but, since 
    # it is very important for it to be secure,
    # clarity is preferred to geekiness :D
    # TODO: disable and delete this method
    if params.has_key? :invoice
      user = User.find params[:invoice]

      user.credit_card_identity_verify!
    end
    render :nothing => true
  end

  def secure_verify_credit_card
    # Method to be called by paypal (IPN) to
    # verify user. Invoice is the account's id.
    # I know this method is verbose but, since 
    # it is very important for it to be secure,
    # clarity is preferred to geekiness :D
    if params.has_key?(:secret) and params[:secret] == Configuration.get("ipn_shared_secret")
      if params.has_key? :invoice
        user = User.find params[:invoice]

        user.credit_card_identity_verify!
      end
    end
    render :nothing => true
  end

  def instructions
    @custom_instructions = Configuration.get('custom_account_instructions')
  end

  private

  def load_account
    @account = current_account
  end

  def sort_and_paginate_accountings
    items_per_page = Configuration.get('default_radacct_results_per_page')

    sort = case params[:sort]
             when 'acct_start_time'         then "AcctStartTime"
             when 'acct_stop_time'          then "AcctStopTime"
             when 'acct_input_octets'       then "AcctInputOctets"
             when 'acct_output_octets'      then "AcctOutputOctets"
             when 'acct_start_time_rev'     then "AcctStartTime DESC"
             when 'acct_stop_time_rev'      then "AcctStopTime DESC"
             when 'acct_input_octets_rev'   then "AcctInputOctets DESC"
             when 'acct_output_octets_rev'  then "AcctOutputOctets DESC"
           end
    if sort.nil?
      params[:sort] = "acct_start_time_rev"
      sort = "AcctStartTime DESC"
    end

    page = params[:page].nil? ? 1 : params[:page]

    @total_accountings =  @account.radius_accountings.count
    @radius_accountings = @account.radius_accountings.order(sort).page(page).per(items_per_page)
  end
end
