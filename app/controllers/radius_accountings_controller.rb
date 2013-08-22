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

class RadiusAccountingsController < ApplicationController
  before_filter :require_operator
  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :users_browser, :to => [ :index ]
    allow :users_finder,  :to => [ :index ]
  end

  respond_to :xml, :json

  # GET /radius_accountings.xml or /radius_accountings.json
  # GET /users/:user_id/radius_accountings.xml or /users/:user_id/radius_accountings.json
  #
  # Querystring Parameters:
  #   * day: filters records of specified date (string in "YYYY-MM-DD" format)
  #   * last: limit records to specified number
  #   * ap: filter records which contain mac address of specified AP in CallingStationId column
  #
  def index
    # scope object
    @radius_accountings = RadiusAccounting.with_full_name.order("AcctStartTime DESC").scoped
    
    # if not requesting accountings of a user and no limit specified default to 50
    if params[:last].nil? and params[:user_id].nil?
      limit = 50
    # if user accounting and no limit specified disable limit
    elsif params[:last].nil? and params[:user_id]
      limit = false
    # limit according to param
    else
      limit = params[:last].to_i  # avoid SQL injection attempts
    end
    
    # filter AP if requested
    if params[:ap]
      # convert semicolon-separted mac address in uppercase dash-separated
      # eg: 00:15:6D:9F:CF:EC becomes 00-15-6D-9F-CF-EC
      mac = params[:ap].gsub(':', '-').upcase
      # search for specified mac address in CalledStationId column
      @radius_accountings = @radius_accountings.where("CalledStationId LIKE ?", "#{mac}:%").scoped
    end
    
    # filter by date if any specified date and format is correct 
    if params[:day]
      begin
        date = Date.parse(params[:day])
      rescue ArgumentError
        # in case day parameter is incorrectly formatted return 400 HTTP error
        result = { 'error' => 'Bad format for day parameter' }
        respond_to do |format|
          format.xml  { render :xml => result, :status => 400 }
          format.json { render :json => result, :status => 400 }
        end
        return
      end
      
      @radius_accountings = @radius_accountings.on_day(date).scoped
    end
    
    if limit
      @radius_accountings = @radius_accountings.limit(limit)
    end
    
    # if requesting accountings of a user
    if params[:user_id]
      # retrieve user
      @user = User.find_by_id_or_username!(params[:user_id])
      # scope radius accounting query to retrieve records belonging to user only
      @radius_accountings = @radius_accountings.where(:UserName => @user.username)
      # backward compatibility: emulate the same behaviour of .last()
      @radius_accountings = @radius_accountings.reverse
    end

    respond_to do |format|
      format.xml
      format.json { render :json => @radius_accountings.to_json }
    end
  end
end