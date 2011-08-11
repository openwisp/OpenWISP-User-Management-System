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

  helper :all
  helper_method :current_account_session, :current_account
  helper_method :current_operator_session, :current_operator
  helper_method :has_mobile?
  protect_from_forgery

  before_filter :set_locale, :set_current_operator, :load_additional_exception_data
  after_filter :reset_last_captcha_code! # reset captcha code after each request for security

  # Additional gem/plugin functionality
  has_mobile_fu


  def toggle_mobile
    session[:mobile_view] = !session[:mobile_view]
    redirect_to current_account ? account_path : root_path
  end

  # TODO: check to see if it works (and if it's still needed)
  # Invalid authenticity token custom error page
  def invalid_token
    render "common/invalid_token"
  end


  protected

  def set_locale
    if params[:locale]
      locale = params[:locale]
    elsif session[:locale]
      locale = session[:locale]
    else
      locale = I18n.default_locale
    end

    if I18n.available_locales.include? locale.to_sym
      I18n.locale = session[:locale] = locale
    end
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
      false
    end
  end

  def require_no_account
    if current_account
      store_location
      flash[:notice] = I18n.t(:Must_be_logged_out)
      redirect_to account_url
      false
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
      false
    end
  end

  def require_no_operator
    if current_operator
      store_location
      flash[:notice] = I18n.t(:Must_be_logged_out)
      redirect_to operator_url(current_operator)
      false
    end
  end

  def require_operator_or_account
    current_operator ? require_operator : require_account
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # Access current_operator from models
  def set_current_operator
    Operator.current_operator = self.current_operator
  end

  def keep_session_data(data)
    old_session_data = session[data]
    yield
    session[data] = old_session_data
  end

  def load_additional_exception_data
    request.env['authlogic_operator'] = current_operator rescue nil
    request.env['authlogic_user'] = current_user rescue nil
  end
end
