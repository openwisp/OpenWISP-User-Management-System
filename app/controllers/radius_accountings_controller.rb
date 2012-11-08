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
  before_filter :load_user
  before_filter :load_radius_accountings

  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :users_browser, :to => [ :index ]
    allow :users_finder,  :to => [ :index ]

  end

  respond_to :xml, :json

  # GET /users/:user_id/radius_accountings?[day=YYYY-MM-DD|last=N]
  def index

    respond_to do |format|
      format.xml
      format.json { render :json => @radius_accountings.to_json }
    end

  end

  private

  def load_user
    @user = User.find_by_id_or_username!(params[:user_id])
  end

  def load_radius_accountings
    if params[:day] and Date.parse(params[:day])
      @radius_accountings = @user.radius_accountings.on_day(Date.parse(params[:day]))
    elsif params[:last]
      @radius_accountings = @user.radius_accountings.last(params[:last].to_i)
    else
      @radius_accountings = @user.radius_accountings
    end
  end
end