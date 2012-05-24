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

class RadiusRepliesController < ApplicationController
  before_filter :require_operator
  before_filter :load_subject
  before_filter :load_radius_reply, :except => [ :index, :new, :create ]

  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :radius_replies_viewer,    :to => [ :index, :show ]
    allow :radius_replies_creator,   :to => [ :new, :create ]
    allow :radius_replies_manager,   :to => [ :edit, :update ]
    allow :radius_replies_destroyer, :to => [ :destroy ]

  end

  respond_to :html, :xml, :json

  # GET /<subject>/:<subject>_id/radius_replies
  def index
    respond_with(@radius_replies = @subject.radius_replies.all)
  end

  # GET /<subject>/:<subject>_id/radius_replies/:id
  def show
    respond_with(@radius_reply)
  end

  # GET /<subject>/:<subject>_id/radius_replies/new
  def new
    respond_with(@radius_reply = @subject.radius_replies.build)
  end

  # POST /<subject>/:<subject>_id/radius_replies
  def create
    @radius_reply = @subject.radius_replies.create(params[:radius_reply])

    respond_with(@radius_reply, :location => subject_url(@subject))
  end

  # GET /<subject>/:<subject>_id/radius_replies/:id/edit
  def edit
    respond_with(@radius_reply)
  end

  # PUT /<subject>/:<subject>_id/radius_replies/:id
  def update
    @radius_reply.update_attributes(params[:radius_reply])

    respond_with(@radius_reply, :location => subject_url(@subject))
  end

  # DELETE /<subject>/:<subject>_id/radius_replies/:id
  def destroy
    @radius_reply.destroy

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

  def load_radius_reply
    @radius_reply = @subject.radius_replies.find(params[:id])
  end

end

