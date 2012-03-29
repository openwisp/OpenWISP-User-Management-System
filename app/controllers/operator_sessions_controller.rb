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

class OperatorSessionsController < ApplicationController
  before_filter :require_no_operator, :only => [:new, :create]
  before_filter :require_operator, :only => :destroy
  skip_before_filter :set_mobile_format

  def new
    @operator_session = OperatorSession.new
  end

  def create
    @operator_session = OperatorSession.new(params[:operator_session])
    if @operator_session.save
      #Avoids session fixations
      keep_session_data :locale do
        reset_session
      end
      
      flash[:notice] = I18n.t(:Login_successful)
      redirect_to operator_url(@operator_session.record)
    else
      render :action => :new
    end
  end

  def destroy
    current_operator_session.destroy
    flash[:notice] = I18n.t(:Logout_successful)
    redirect_to operator_login_url
  end
end
