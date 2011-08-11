Owums::Application.routes.draw do
  #### Named Routes --->
  match '/account/login' => 'account_sessions#new', :as => :account_login
  match '/account/logout' => 'account_sessions#destroy', :as => :account_logout, :via => 'delete'
  match '/account/signup' => 'accounts#new', :as => :account_registration
  match '/account/instructions' => 'accounts#instructions', :as => :account_instructions
  match '/account/reset' => 'password_resets#new', :as => :password_reset
  match '/account/verification' => 'accounts#verification', :as => :verification
  match '/account/verify_credit_card' => 'accounts#verify_credit_card', :as => :verify_credit_card, :via => 'post'
  match '/account/secure_verify_credit_card' => 'accounts#secure_verify_credit_card', :as => :secure_verify_credit_card, :via => 'post'

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
  end

  resources :online_users, :only => :index
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

  #### Root Route --->
  root :to => "accounts#instructions"
end
