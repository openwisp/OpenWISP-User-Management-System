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

class AccountsController < ApplicationController
  before_filter :require_account, :only => [
      :show, :edit, :update, :ajax_accounting_search
  ], :except => :instructions

  before_filter :require_no_account, :only => [
      :new, :create, :verify_credit_card, :secure_verify_credit_card
  ], :except => :instructions

  before_filter :require_no_operator

  before_filter :load_account, :except => [ :new, :create, :verify ]

  protect_from_forgery :except => [ :verify_credit_card, :secure_verify_credit_card ]

  STATS_PERIOD = 14

  def load_account
    @account = @current_account
  end

  def new
    @account = Account.new( :verification_method => Account::VERIFY_BY_MOBILE, :state => 'Italy' )
    @countries = Country.find :all, :conditions => "disabled = 'f'", :order => :printable_name
    @mobile_prefixes = MobilePrefix.find :all, :conditions => "disabled = 'f'", :order => :prefix

    respond_to do |format|
      format.html
      format.mobile
    end
  end

  def create
    @account = Account.new(params[:account])
    @countries = Country.find :all, :conditions => "disabled = 'f'", :order => :printable_name
    @mobile_prefixes = MobilePrefix.find :all, :conditions => "disabled = 'f'", :order => :prefix

    @account.radius_groups << RadiusGroup.find_by_name(Configuration.get('default_radius_group'))

    if @account.save_with_captcha
      redirect_to account_path
    else
      respond_to do |format|
        format.html   { render :action => :new }
        format.mobile { render :action => :new }
      end
    end
  end

  def show
    if not Account::SELFVERIFICATION_METHODS.include?(@account.verification_method) and !@account.verified?
      respond_to do |format|
        format.html   { render :action => :no_verification }
        format.mobile { render :action => :no_verification }
      end
    elsif @current_operator.nil? and !@account.verified?
      respond_to do |format|
        format.html   { render :action => :verification }
        format.mobile { render :action => :verification }
      end
    else
      respond_to do |format|
        format.html
        format.mobile
      end
    end
  end

  def edit
    if not Account::SELFVERIFICATION_METHODS.include?(@account.verification_method) and !@account.verified?
      respond_to do |format|
        format.html   { render :action => :no_verification }
        format.mobile { render :action => :no_verification }
      end
    elsif @current_operator.nil? and !@account.verified?
      respond_to do |format|
        format.html   { render :action => :verification }
        format.mobile { render :action => :verification }
      end
    else
      @countries = Country.find :all, :conditions => "disabled = 'f'", :order => :printable_name
      @mobile_prefixes = MobilePrefix.find :all, :conditions => "disabled = 'f'", :order => :prefix
      respond_to do |format|
        format.html
        format.mobile
      end
    end
  end

  def update
    if !@current_operator.nil? or !@account.verified?
      render :action => :verification
    else
      @countries = Country.find :all, :conditions => "disabled = 'f'", :order => :printable_name
      @mobile_prefixes = MobilePrefix.find :all, :conditions => "disabled = 'f'", :order => :prefix

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
          redirect_to :root
        else
          flash[:notice] = I18n.t(:Account_updated)
          redirect_to account_url
        end
      else
        render :action => :edit
      end
    end
  end

  def verification
    @account = self.current_account
    if @account.nil? # Account expired (and removed by the housekeeping backgroundrb job)
      respond_to do |format|
        if request.xhr? # Ajax request
          format.html   { render :partial => 'expired' }
          format.mobile { render :partial => 'expired' }
        else
          format.html   { render :action => 'expired' }
          format.mobile { render :action => 'expired' }
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

  def ajax_accounting_search
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
    @radius_accountings = @account.radius_accountings.paginate :page => page, :order => sort, :per_page => items_per_page

    render :partial => "common/radius_accounting_list", :locals => { :action => 'ajax_accounting_search', :accountings => @radius_accountings, :total_accountings => @total_accountings }
  end

end
