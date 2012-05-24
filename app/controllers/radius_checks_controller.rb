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

class RadiusChecksController < ApplicationController
  before_filter :require_operator
  before_filter :load_subject
  before_filter :load_radius_check, :except => [ :index, :new, :create ]

  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :radius_checks_viewer,    :to => [ :index, :show ]
    allow :radius_checks_creator,   :to => [ :new, :create ]
    allow :radius_checks_manager,   :to => [ :edit, :update ]
    allow :radius_checks_destroyer, :to => [ :destroy ]

  end

  respond_to :html, :xml, :json

  # GET /<subject>/:<subject>_id/radius_checks
  def index
    respond_with(@radius_checks = @subject.radius_checks.all)
  end

  # GET /<subject>/:<subject>_id/radius_checks/:id
  def show
    respond_with(@radius_check)
  end

  # GET /<subject>/:<subject>_id/radius_checks/new
  def new
    respond_with(@radius_check = @subject.radius_checks.build)
  end

  # POST /<subject>/:<subject>_id/radius_checks
  def create
    @radius_check = @subject.radius_checks.create(params[:radius_check])

    respond_with(@radius_check, :location => subject_url(@subject))
  end

  # GET /<subject>/:<subject>_id/radius_checks/:id/edit
  def edit
    respond_with(@radius_check)
  end

  # PUT /<subject>/:<subject>_id/radius_checks/:id
  def update
    @radius_check.update_attributes(params[:radius_check])

    respond_with(@radius_check, :location => subject_url(@subject))
  end

  # DELETE /<subject>/:<subject>_id/radius_checks/:id
  def destroy
    @radius_check.destroy

    respond_to do |format|
      format.html { redirect_to subject_url(@subject) }
      format.any { render :nothing => true, :status => :ok }
    end
  end

  private

  def load_subject
    @subject = params[:user_id].present? ? User.find_by_id_or_username!(params[:user_id]) :
                                           RadiusGroup.find(params[:radius_group_id])
  end

  def load_radius_check
    @radius_check = @subject.radius_checks.find(params[:id])
  end

end

