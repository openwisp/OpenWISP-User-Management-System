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

class UsersController < ApplicationController
  before_filter :require_operator
  before_filter :load_user, :except => [ :index, :new, :create, :ajax_search ]
 
  access_control :subject_method => :current_operator do
    default :deny
    
    allow :users_viewer,     :to => [ :index, :show, :ajax_search, :ajax_accounting_search ]
    allow :users_registrant, :to => [ :new, :create ]
    allow :users_manager,    :to => [ :new, :create, :edit, :update ]
    allow :user_destroyer,   :to => [ :destroy ]
  end

  STATS_PERIOD = 14

  def load_user
    @user = User.find(params[:id])
  end
  
  def index
    now = Date.today
    cur = now - 14.days
    registered_users = []
    logins = []
    ulogins = []
    traffic = []
    traffic_in = []
    traffic_out = []
    categories = []
    countries = {}
    @show_graphs = false
    @show_login_graphs = false
    @show_traffic_graphs = false

    @last_logins = RadiusAccounting::last_logins(5)
    @online_users = RadiusAccounting::online_users(5)
    @last_registered = User.last_registered(5)
    @top_traffic_users = User.top_traffic(5)

    while cur <= now do
      user_count = User.count( :conditions => "DATE(verified_at) <= '#{cur.to_s}'" )
      @show_graphs = true if user_count > 0

      registered_users.push :name => cur.to_s, :value => user_count
      login_count = RadiusAccounting.count( :conditions => "DATE(AcctStartTime) = '#{cur.to_s}'" )
      ulogin_count = RadiusAccounting.count( 'UserName', :distinct => true, :conditions => "DATE(AcctStartTime) = '#{cur.to_s}'" )
      @show_login_graphs = true if login_count > 0 and ulogin_count > 0

      traffic_in_count = RadiusAccounting.sum( 'AcctInputOctets', :conditions => "DATE(AcctStartTime) = '#{cur.to_s}'")
      traffic_out_count = RadiusAccounting.sum( 'AcctOutputOctets', :conditions => "DATE(AcctStartTime) = '#{cur.to_s}'")
      @show_traffic_graphs = true if traffic_in_count > 0 and traffic_out_count > 0

      categories.push cur.to_s
      logins.push login_count
      ulogins.push ulogin_count
      traffic.push traffic_in_count + traffic_out_count
      traffic_in.push traffic_in_count
      traffic_out.push traffic_out_count
      cur += 1.day
    end

    if @show_traffic_graphs
      @traffic_xml_data = 
        render_to_string :template => "common/MSFusionChart.xml", 
                         :locals => { :caption => t(:Traffic),
                                      :suffix => 'B',
                                      :categories => categories, 
                                      :format_number_scale => 1,
                                      :decimalPrecision => 2,
                                      :series => [ { :name => t(:Traffic_total), :color => '5E5E5E', :data => traffic },
                                                   { :name => t(:Upload), :color => '26A4F7', :data => traffic_in }, 
                                                   { :name => t(:Download), :color => 'FDC12E', :data => traffic_out } ]
                                    }, :layout => false
    else
      @traffic_xml_data = ""
    end

    if @show_login_graphs
      @logins_xml_data = 
        render_to_string :template => "common/MSFusionChart.xml",
                         :locals => { :caption => t(:Logins),
                                      :categories => categories,
                                      :series => [ { :name => t(:Logins), :color => '56B9F9', :data => logins }, 
                                                   { :name => t(:Unique_logins), :color => 'FDC12E', :data => ulogins } ]
                                    },
                         :layout => false
    else
      @logins_xml_data = ""
    end

    if @show_graphs
      @accounts_xml_data = 
        render_to_string :template => "common/SSFusionChart.xml", 
                         :locals => { :caption => t(:Registered_users), :data => registered_users }, 
                         :layout => false
      @countries_xml_data = 
        render_to_string :template => "common/SSFusionChart.xml",
                         :locals => { :caption => t(:Users_nationality), :data => countries.to_a.map{|values| values[1]} }, 
                         :layout => false
    else
      @accounts_xml_data = @countries_xml_data = ""
    end
  end
  
  def new
    @user = User.new( :eula_acceptance => true, :privacy_acceptance => true, :state => 'Italy', :verification_method => User::VERIFY_BY_DOCUMENT )
    @user.verified = true
    @user.radius_group_ids = [ RadiusGroup::users_group ]

    @countries = Country.find :all, :conditions => "disabled = 'f'", :order => :printable_name
    @mobile_prefixes = MobilePrefix.find :all, :conditions => "disabled = 'f'", :order => :prefix
    @radius_groups = RadiusGroup.all
  end
  
  def create
    @user = User.new(params[:user])
    
    # Parameter anti-tampering
    unless current_operator.has_role? 'users_manager'
      @user.radius_group_ids = [ RadiusGroup::users_group ]
      @user.verified = @user.active = true
    end
    
    @countries = Country.find :all, :conditions => "disabled = 'f'", :order => :printable_name
    @mobile_prefixes = MobilePrefix.find :all, :conditions => "disabled = 'f'", :order => :prefix
    @radius_groups = RadiusGroup.all

    if @user.save
      current_account_session.destroy unless current_account_session.nil?
            
      unless current_operator.has_role? 'users_manager'
        redirect_to new_user_url
      else
        redirect_to users_url
      end
    else
      render :action => :new
    end
  end
  
  def show
    now = Date.today
    cur = now - STATS_PERIOD.days
    ups = []
    downs = []
    logins = []
    categories = []
    yAxisMaxValue = 0
    @show_graphs = false 
    while cur <= now do
      up_traffic   = @user.radius_accountings.sum( 'AcctInputOctets', :conditions => "DATE(AcctStartTime) = '#{cur.to_s}'" )
      down_traffic = @user.radius_accountings.sum( 'AcctOutputOctets', :conditions => "DATE(AcctStartTime) = '#{cur.to_s}'" )
      time_count = 0
      sessions = @user.radius_accountings.find(:all, :conditions => "Date(AcctStartTime) = '#{cur.to_s}'")
      
      sessions.each do |session|
        if session.AcctStopTime
          time_count += session.acct_stop_time - session.acct_start_time
        else
          time_count += Time.now - session.acct_start_time
        end
      end

      logins.push :name => cur.to_s, :value => (time_count.to_i / 60.0)
      categories.push cur.to_s
      ups.push    up_traffic
      downs.push  down_traffic
      
      yAxisMaxValue = down_traffic if yAxisMaxValue < down_traffic
      yAxisMaxValue = up_traffic if yAxisMaxValue < up_traffic  
      cur += 1.day
    end
    
    if yAxisMaxValue > 0
      @show_graphs = true
      @login_xml_data = 
        render_to_string :template => "common/SSFusionChart.xml", 
                         :locals => { :caption => t(:Last_x_days_time, :count => STATS_PERIOD),
                                      :suffix => 'Min',
                                      :decimal_precision => 0,
                                      :data => logins
                                    }, :layout => false
      @traffic_xml_data = 
        render_to_string :template => "common/MSFusionChart.xml", 
                         :locals => { :caption => t(:Last_x_days_traffic, :count => STATS_PERIOD),
                                      :suffix => 'B',
                                      :categories => categories, 
                                      :format_number_scale => 1,
                                      :decimalPrecision => 2,
                                      :series => [ { :name => t(:Upload), :color => '56B9F9', :data => ups }, 
                                                   { :name => t(:Download), :color => 'FDC12E', :data => downs } ]
                                    }, :layout => false
    else
      @login_xml_data = @traffic_xml_data = "" 
    end
  end
 
  def edit
    @countries = Country.find :all, :conditions => "disabled = 'f'", :order => :printable_name
    @mobile_prefixes = MobilePrefix.find :all, :conditions => "disabled = 'f'", :order => :prefix
    @radius_groups = RadiusGroup.all
  end
  
  def update
    # Parameter anti-tampering
    params[:user][:radius_group_ids] = nil unless current_operator.has_role? 'users_manager'
    
    @countries = Country.find :all, :conditions => "disabled = 'f'", :order => :printable_name
    @mobile_prefixes = MobilePrefix.find :all, :conditions => "disabled = 'f'", :order => :prefix
    @radius_groups = RadiusGroup.all
    
    if @user.update_attributes(params[:user])
      current_account_session.destroy unless current_account_session.nil?
            
      flash[:notice] = I18n.t(:Account_updated)
      redirect_to user_url
    else
      render :action => :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url
  end

  def ajax_search
    items_per_page = Configuration.get('default_user_search_results_per_page')

    sort = case params[:sort]
      when 'registered_at'      then "created_at"
      when 'username'           then "username"
      when 'given_name'         then "given_name"
      when 'surname'            then "surname"
      when 'state'              then "state"
      when 'city'               then "city"
      when 'address'            then "address"
      when 'verified'           then "verified"
      when 'active'             then "active"
      when 'registered_at_rev'  then "created_at DESC"
      when 'username_rev'       then "username DESC"
      when 'given_name_rev'     then "given_name DESC"
      when 'surname_rev'        then "surname DESC"
      when 'state_rev'          then "state DESC"
      when 'city_rev'           then "city DESC"
      when 'address_rev'        then "address DESC"
      when 'verified_rev'       then "verified DESC"
      when 'active_rev'         then "active DESC"
    end
    if sort.nil?
      params[:sort] = "registered_at_rev"
      sort = "created_at DESC"
    end  

    search = params[:search]
    page = params[:page].nil? ? 1 : params[:page]
    
    unless search.nil?
      search.gsub(/\\/, '\&\&').gsub(/'/, "''")
      conditions = [ "given_name LIKE ? OR surname LIKE ? OR username LIKE ? OR CONCAT(mobile_prefix,mobile_suffix) LIKE ? OR CONCAT_WS(' ', given_name, surname) LIKE ? OR CONCAT_WS(' ', surname, given_name) LIKE ?", "%#{search}%","%#{search}%","%#{search}%","%#{search}%","%#{search}%","%#{search}%" ] 
    else
      conditions = []
    end

    @total_users = User.count :conditions => conditions
    @users = User.paginate :page => page, :order => sort, :conditions => conditions, :per_page => items_per_page

    render :partial => "list", :locals => { :action => 'ajax_search', :users => @users, :total_users => @total_users }
  end

  def ajax_accounting_search
    items_per_page = Configuration.get('default_radacct_results_per_page')

    sort = case params[:sort]
      when 'acct_start_time'          then "AcctStartTime"
      when 'acct_stop_time'           then "AcctStopTime"
      when 'acct_input_octects'       then "AcctInputOctets"
      when 'acct_output_octects'      then "AcctOutputOctets"
      when 'calling_station_id'       then "CallingStationId"
      when 'framed_ip_address'        then "FramedIPAddress"
      when 'acct_start_time_rev'      then "AcctStartTime DESC"
      when 'acct_stop_time_rev'       then "AcctStopTime DESC"
      when 'acct_input_octects_rev'   then "AcctInputOctets DESC"
      when 'acct_output_octects_rev'  then "AcctOutputOctets DESC"
      when 'calling_station_id_rev'   then "CallingStationId DESC"
      when 'framed_ip_address_rev'    then "FramedIPAddress DESC"
    end
    if sort.nil?
      params[:sort] = "acct_start_time_rev"
      sort = "AcctStartTime DESC"
    end

    search = params[:search]
    page = params[:page].nil? ? 1 : params[:page]

    @total_accountings =  @user.radius_accountings.count
    @radius_accountings = @user.radius_accountings.paginate :page => page, :order => sort, :per_page => items_per_page

    render :partial => "common/radius_accounting_list", :locals => { :action => 'ajax_accounting_search', :accountings => @radius_accountings, :total_accountings => @total_accountings } 
  end

end
