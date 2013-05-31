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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalid_token
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  rescue_from Acl9::AccessDenied, :with => :render_403

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

  def render_403
    render :nothing => true, :status => :forbidden
  end

  def render_404
    render :nothing => true, :status => :not_found
  end

  def render_if_xml_restful_enabled(params={})
    if Configuration.get("enable_account_xml_restful_api") == "yes"
      render params
    else
      render :xml => { :error => 'disabled' }, :status => :unauthorized
    end
  end

  protected

  def set_locale
    if params[:locale]
      locale = params[:locale]
    elsif session[:locale]
      locale = session[:locale]
    else
      locale = set_locale_from_preference
    end

    if I18n.available_locales.include? locale.to_sym
      I18n.locale = session[:locale] = locale
    end
  end
  
  def set_locale_from_preference
    # set locale to the first preferred language of the user if present in the available locales, otherwise set to english
    if I18n.available_locales.include? preferred_user_language.to_sym
      preferred_user_language.to_sym
    else
      :en
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
    if current_operator
      # Check if the request IP address match the one used on login
      if current_operator.current_login_ip and current_operator.current_login_ip != request.remote_ip
        # Force current operator logout
        current_operator_session.destroy
        current_operator.current_login_ip = nil
        current_operator.save!
        flash[:notice] = I18n.t(:Your_ip_address_changed_since_logon)
        redirect_to new_operator_session_url
        return false
      end
    else
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

  # URL helpers for controllers
  def subject_url(subject)
    subject.is_a?(User) ? user_url(subject) : radius_group_url(subject)
  end
  
  private
  
  def preferred_user_language
    unless request.env['HTTP_ACCEPT_LANGUAGE'].nil?
      request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    else
      I18n.default_locale
    end
  end
end
