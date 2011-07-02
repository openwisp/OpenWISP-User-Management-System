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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalid_token

  include ExceptionNotification::Notifiable
  include SimpleCaptcha::ControllerHelpers


  helper :all
  helper_method :current_account_session, :current_account
  helper_method :current_operator_session, :current_operator
  helper_method :has_mobile?
  filter_parameter_logging :password, :password_confirmation, :crypted_password
  protect_from_forgery

  # Access current_operator from models
  before_filter :set_current_operator

  # Set locale from session
  before_filter :set_locale

  # Controllers for which there is no mobile layout
  WITHOUT_MOBILE_TEMPLATE = %w(operators operator_sessions users configurations stats)

  # Load mobile_fu only for controllers
  # with mobile views
  before_filter :load_mobile_fu

  def set_session_locale
    session[:locale] = params[:locale]

    # Redirect to HTTP_REFERER without parameters or root
    back = request.env['HTTP_REFERER']
    redirect_to(back ? back.split('?').first : root_path)
  end

  def toggle_mobile_view
    session[:mobile_view] = !session[:mobile_view]
    redirect_to root_path
  end

  # Invalid authenticity token custom error page
  def invalid_token
    render "common/invalid_token"
  end

  protected

  def available_locales
    AVAILABLE_LOCALES
  end

  def set_locale
    I18n.locale = available_locales.include?(session[:locale]) ? session[:locale] : nil
  end

  def has_mobile?
    !WITHOUT_MOBILE_TEMPLATE.include?(controller_name)
  end

  def load_mobile_fu
    self.class.has_mobile_fu if has_mobile?
  end

  def current_account_session
    return @current_account_session if defined?(@current_account_session)
    @current_account_session = AccountSession.find
  end

  def current_account
    return @current_account if defined?(@current_account)
    @current_account = current_account_session && current_account_session.record
  end

  def require_account
    unless current_account
      store_location
      flash[:notice] = I18n.t(:Must_be_logged_in)
      redirect_to new_account_session_url
      return false
    end
  end

  def require_no_account
    if current_account
      store_location
      flash[:notice] = I18n.t(:Must_be_logged_out)
      redirect_to account_url
      return false
    end
  end

  def current_operator_session
    return @current_operator_session if defined?(@current_operator_session)
    @current_operator_session = OperatorSession.find
  end

  def current_operator
    return @current_operator if defined?(@current_operator)
    @current_operator = current_operator_session && current_operator_session.record
  end

  def require_operator
    unless current_operator
      store_location
      flash[:notice] = I18n.t(:Must_be_logged_in)
      redirect_to new_operator_session_url
      return false
    end
  end

  def require_no_operator
    if current_operator
      store_location
      flash[:notice] = I18n.t(:Must_be_logged_out)
      redirect_to operator_url current_operator
      return false
    end
  end

  def require_operator_or_account
    current_operator ? require_operator : require_account
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # Access current_operator from models
  def set_current_operator
    Operator.current_operator = self.current_operator
  end

  # ExceptionNotify extra data
  exception_data :additional_data

  def additional_data
    { :operator => current_operator,
      :user => current_account }
  end

end
