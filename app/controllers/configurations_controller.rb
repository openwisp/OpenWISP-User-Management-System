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

class ConfigurationsController < ApplicationController
  before_filter :require_operator
  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :configurations_manager
  end

  def edit
    @configuration = Configuration.find(params[:id])
    
    html_configs = [
      'verification_explain_mobile_it',
      'verification_explain_mobile_en',
      'verification_explain_creditcard_it',
      'verification_explain_creditcard_en',
      'custom_account_instructions_it',
      'custom_account_instructions_en',
      'invoice_owner_en',
      'invoice_owner_it'
    ]
    
    @html = html_configs.include?(@configuration.key)
  end

  def update
    @configuration = Configuration.find(params[:id])
    if @configuration.update_attributes(params[:configuration])
      flash[:notice] = I18n.t(:Configuration_key_updated)
      redirect_to configurations_path
    else
      render :action => :edit
    end
  end

  def index
    @configurations = Configuration.order("configurations.key")
  end

end
