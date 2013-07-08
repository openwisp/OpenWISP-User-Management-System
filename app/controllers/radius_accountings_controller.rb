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
  #before_filter :load_user
  #before_filter :load_radius_accountings

  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :users_browser, :to => [ :index ]
    allow :users_finder,  :to => [ :index ]

  end

  respond_to :xml, :json

  # TODO:
  # last vs limit?
  # limit uses less resources
  # @user.radius_accountings.with_full_name.limit(params[:last].to_i).order("id DESC").reverse
  # use .scoped to clean up and DRY
  # generalize last and day
  # implement 404 (look for user first, then select radius accountings which have that username)

  # GET /radius_accountings?[limit=N|ap=MAC_ADDRESS]
  # GET /users/:user_id/radius_accountings?[day=YYYY-MM-DD|last=N]
  def index
    # if requesting accountings of a user
    unless params[:user_id].nil?
      @user = User.find_by_id_or_username!(params[:user_id])
      # filter by date if 
      if params[:day] and Date.parse(params[:day])
        @radius_accountings = @user.radius_accountings.with_full_name.on_day(Date.parse(params[:day]))
      elsif params[:last]
        @radius_accountings = @user.radius_accountings.with_full_name.last(params[:last].to_i)
      else
        @radius_accountings = @user.radius_accountings.with_full_name
      end
    # requesting all the accountings
  else
      # determine limit if present, otherwise default limit is 50, maximum limit is also 50
      limit = (!params[:limit].nil? and params[:limit].to_i <= 50) ? params[:limit] : 50
      
      # filter AP if requested
      unless params[:ap].nil?
        # convert semicolon-separted mac address in uppercase dash-separated
        # eg: 00:15:6D:9F:CF:EC becomes 00-15-6D-9F-CF-EC
        mac = params[:ap].gsub(':', '-').upcase
        @radius_accountings = RadiusAccounting.with_full_name.where("CalledStationId LIKE ?", "#{mac}:%").order("AcctStartTime DESC").limit(limit)
      else
        @radius_accountings = RadiusAccounting.with_full_name.order("AcctStartTime DESC").limit(limit)
      end
    end

    respond_to do |format|
      format.xml
      format.json { render :json => @radius_accountings.to_json }
    end
  end

  private

  #def load_user
  #  @user = User.find_by_id_or_username!(params[:user_id])
  #end
  #
  #def load_radius_accountings
  #  if params[:day] and Date.parse(params[:day])
  #    @radius_accountings = @user.radius_accountings.on_day(Date.parse(params[:day]))
  #  elsif params[:last]
  #    @radius_accountings = @user.radius_accountings.last(params[:last].to_i)
  #  else
  #    @radius_accountings = @user.radius_accountings
  #  end
  #end
end