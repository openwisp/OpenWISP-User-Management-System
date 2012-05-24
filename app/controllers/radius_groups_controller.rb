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

class RadiusGroupsController < ApplicationController
  before_filter :require_operator
  before_filter :load_radius_group, :except => [ :index, :new, :create ]

  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :radius_groups_creator,   :to => [ :new, :create ]
    allow :radius_groups_viewer,    :to => [ :index, :show ]
    allow :radius_groups_manager,   :to => [ :edit, :update ]
    allow :radius_groups_destroyer, :to => [ :destroy ]
  end

  respond_to :html, :xml, :json

  # GET /radius_groups
  def index
    respond_with(@radius_groups = RadiusGroup.all(:order => [:priority, :name]))
  end

  # GET /radius_groups/:id
  def show
    respond_with(@radius_group)
  end

  # GET /radius_groups/new
  def new
    respond_with(@radius_group = RadiusGroup.new)
  end

  # POST /radius_groups
  def create
    @radius_group = RadiusGroup.create(params[:radius_group])

    respond_with(@radius_group, :location => radius_groups_url)
  end

  # GET /radius_groups/:id/edit
  def edit
    respond_with(@radius_group)
  end

  # PUT /radius_groups/:id
  def update
    @radius_group.update_attributes(params[:radius_group])

    respond_with(@radius_group, :location => radius_groups_url)
  end

  # DELETE /radius_groups/:id
  def destroy
    @radius_group.destroy

    respond_to do |format|
      format.html { redirect_to radius_groups_url }
      format.any { render :nothing => true, :status => :ok }
    end
  end

  private

  def load_radius_group
    @radius_group = RadiusGroup.find(params[:id])
  end

end

