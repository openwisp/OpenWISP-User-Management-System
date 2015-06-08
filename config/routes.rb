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

require 'rails/application'

module RouteScoper
  # Keep the rescue so that you can revert to not having a
  # subdirectory when in development and test modes
  def self.root
    Rails.application.config.root_directory
  rescue NameError
    '/'
  end
end

Owums::Application.routes.draw do
  scope RouteScoper.root do
    #### Named Routes --->
    match '/account/login' => 'account_sessions#new', :as => :account_login
    match '/account/logout' => 'account_sessions#destroy', :as => :account_logout, :via => 'delete'
    match '/account/signup' => 'accounts#new', :as => :account_registration
    match '/account/instructions' => 'accounts#instructions', :as => :account_instructions
    match '/account/reset' => 'password_resets#new', :as => :password_reset
    match '/account/verification' => 'accounts#verification', :as => :verification
    match '/account/status.json' => 'accounts#status_json', :as => :account_status
    match '/account/gestpay_verify_credit_card' => 'accounts#gestpay_verify_credit_card', :as => :gestpay_verify_credit_card, :via => 'post'
    match '/account/gestpay_verified_by_visa' => 'accounts#gestpay_verified_by_visa', :as => :gestpay_verified_by_visa, :via => 'post'
    match '/account/additional_fields' => 'accounts#additional_fields', :as => :additional_fields

    match '/users/browse' => 'users#index', :as => :users_browse
    match '/users/search' => 'users#search', :as => :users_search
    match '/users/find' => 'users#find', :via => 'post'

    match '/mobile_phone_password_resets/:id/recovery_confirmation' => 'mobile_phone_password_resets#recovery_confirmation', :as => :recovery_confirmation

    captcha_route
    match '/spoken_captcha.mp3' => 'spoken_captcha#show', :as => :spoken_captcha

    match '/operator/login' => 'operator_sessions#new', :as => :operator_login
    match '/operator/logout' => 'operator_sessions#destroy', :as => :operator_logout, :via => :delete

    match '/toggle_mobile' => 'application#toggle_mobile', :as => :toggle_mobile
    ####################

    #### Resources --->
    resource :account do
      resources :stats, :only => :show
    end
    resource :account_session
    resource :operator_session
    resources :configurations
    resources :users do
      resources :stats, :only => :show
      resources :radius_checks
      resources :radius_replies
      resources :radius_accountings, :only => :index # API method
    end
    resources :radius_groups do
      resources :radius_checks
      resources :radius_replies
    end
    resources :online_users, :only => :index # API method
    resources :radius_accountings, :only => :index # API method
    resources :operators
    resources :password_resets
    resources :email_password_resets

    resources :mobile_phone_password_resets do
      get :verification, :on => :member
    end

    resources :stats, :only => [:index, :show] do
      post :export, :on => :collection
    end
    ###################

    #### Social Auth
    if CONFIG['social_login_enabled']
      match '/auth/:provider/callback' => 'social_auth#create', :as => :callback
      match '/auth/failure' => 'social_auth#failure', :as => :failure
    end

    #### Root Route --->
    root :to => "accounts#instructions"
  end
end
