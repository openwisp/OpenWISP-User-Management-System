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
    :show, :edit, :update, :gestpay_verify_credit_card, :gestpay_verified_by_visa
  ]

  before_filter :require_no_account, :only => [
    :new, :create
  ]

  before_filter :get_credit_card_verification_cost, :only => [
    :new, :create, :verification, :gestpay_verify_credit_card
  ]

  before_filter :require_no_operator

  before_filter :load_account, :except => [ :new, :create ]

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
      # by default no verification method is selected
      @verification_method = false

      respond_to do |format|
        format.html { redirect_to account_path }
        format.mobile { redirect_to account_path }
        format.xml { render_if_xml_restful_enabled :nothing => true, :status => :created }
      end
    else
      # select verification method automatically
      @verification_method = params[:account][:verification_method]

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
        format.html   { redirect_to :action => :verification }
        format.mobile { redirect_to :action => :verification }
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
        format.html   { redirect_to :action => :verification }
        format.mobile { redirect_to :action => :verification }
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

  # additional fields
  # implemented to ask additional fields after social login
  def additional_fields
    if @account.nil?
      redirect_to :action => :new
    elsif @account.verified? or !@current_operator.nil?
      redirect_to :action => :show
    else
      if request.method == 'POST' and @account.update_attributes(request.params[:account])
        # mark as verified and log in
        @account.verified = true
        @account.current_login_ip = request.remote_ip
        @account.save
        @account.captive_portal_login!
        # determine URL for redirect (defaults to account URL)
        config_url = Configuration.get('social_login_success_url', '')
        redirect_url = config_url != '' ? config_url : account_url
        redirect_to redirect_url
        return nil
      end

      @mobile_prefixes = MobilePrefix.all
      respond_to do |format|
        format.html
        format.mobile
      end
    end
  end

  def update
    if !@current_operator.nil? or !@account.verified?
      respond_to do |format|
        format.html   { redirect_to :action => :verification }
        format.mobile { redirect_to :action => :verification }
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

  # before_filters: (load_account, get_credit_card_verification_cost)
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
    elsif @account.verified?
      flash[:notice] = I18n.t(:Account_verified_successfully)
      redirect_to account_path
    elsif @account.verify_with_social?
      redirect_to additional_fields_url
    else
      if CONFIG['gestpay_enabled']
        # delete any remaining flash message
        unless flash[:error].nil?
          flash.delete(:error)
        end
      end
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

  # account status
  def status_json
    unless @account.nil?
      remaining_time = @account.verification_time_remaining rescue 0

      data = {
        :is_verified => @account.verified?,
        :is_expired => false,
        :remaining_time => remaining_time
      }
    else
      data = {
        :is_verified => false,
        :is_expired => true,
        :remaining_time => 0
      }
    end

    render :json => data
  end

  # before_filter: get_credit_card_verification_cost
  def gestpay_verify_credit_card
    @currency_code = Configuration.get('gestpay_currency')
    @verified_by_visa = false

    unless CONFIG['gestpay_enabled']
      render :nothing => true, :status => '403'
      return false
    end

    unless @account.nil?
      validation = @account.gestpay_s2s_verify_credit_card(request, params, @credit_card_verification_cost, @currency_code)
    else
      validation = {
        :transaction_result => 'KO',
        :error_code => '000',
        :error_description => I18n.t(:Verification_time_expired)
      }
      flash[:expired] = true
    end

    if validation[:transaction_result] == 'OK'
      unless flash[:error].nil?
        flash.delete(:error)
      end
      flash[:notice] = I18n.t(:Account_verified_successfully)
    elsif validation[:error_code] == '8006'
      @verified_by_visa = {
        :a => validation[:a],
        :b => validation[:b],
        :c => url_for(:action => :gestpay_verified_by_visa, :only_path => false),
        :url => validation[:url]
      }
    else
      # translate gestpay error message if possible otherwise just return the string
      begin
        flash[:error] = I18n.translate!(('gestpay_error_'+validation[:error_code]).parameterize.underscore.to_sym, :raise => true)
      rescue I18n::MissingTranslationData, TypeError
        flash[:error] = validation[:error_description]
      end
    end

    respond_to do |format|
      format.html{ redirect_to verification_path }
      format.js{
        @is_mobile = params[:mobile].nil? ? false : true
        @template_suffix = @is_mobile ? 'mobile.erb' : 'html.erb'
      }
    end
  end

  def gestpay_verified_by_visa
    if not CONFIG['gestpay_enabled']
      head 404
    # if PaRes param is missing from POST request return 400 Bad Request
    elsif not params[:PaRes]
      head 400
    else
      # perform gestpay webservice verification again
      validation = @account.gestpay_s2s_verified_by_visa(params[:PaRes], request.remote_ip)
      # if success redirect to account page
      if validation[:transaction_result] == 'OK'
        flash[:notice] = I18n.t(:Account_verified_successfully)
        redirect_to account_path
      # else render error template
      else
        render :template => 'accounts/gestpay_verified_by_visa_error'
      end
    end
  end

  def instructions
    begin
      @custom_instructions = Configuration.get('custom_account_instructions_%s' % I18n.locale).html_safe
    rescue NoMethodError
      @custom_instructions = Configuration.get('custom_account_instructions_en').html_safe
    end
  end

  private

  def load_account
    @account = current_account
  end

  def get_credit_card_verification_cost
    if not CONFIG['gestpay_enabled']
      return @credit_card_verification = false
    end
    # verification cost, 0 if verification web service method us used
    if Configuration.get('gestpay_webservice_method') == 'verification'
      @credit_card_verification_cost = 0
    else
      @credit_card_verification_cost = Configuration.get('credit_card_verification_cost', '1').to_f
    end
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
