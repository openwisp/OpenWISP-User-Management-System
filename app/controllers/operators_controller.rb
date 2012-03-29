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

class OperatorsController < ApplicationController
  before_filter :require_operator
  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :operators_manager

    allow all, :to => :show, :if => :looking_at_stats_of_self
  end

  def index
    @operators = Operator.all :order => 'login ASC'
  end

  def show
    @operator = Operator.find(params[:id])
  end

  def new
    @operator = Operator.new
  end

  def create
    @operator = Operator.new(params[:operator])
    if @operator.save
      flash[:notice] = I18n.t(:Operator_created_success)
      redirect_to operators_path
    else
      render :action => :new
    end
  end

  def edit
    @operator = Operator.find(params[:id])
  end

  def update
    @operator = Operator.find(params[:id])
    if @operator.update_attributes(params[:operator])
      flash[:notice] = I18n.t(:Operator_updated_success)
      redirect_to operators_path
    else
      render :action => :edit
    end
  end

  def destroy
    Operator.find(params[:id]).destroy
    flash[:notice] = I18n.t(:Operator_deleted_success)
    redirect_to operators_path
  end

  private

  def looking_at_stats_of_self
    current_operator == Operator.find(params[:id])
  end
end
