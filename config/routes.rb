ActionController::Routing::Routes.draw do |map|

  # Common user (client) named routes
  map.account_login '/account/login', :controller => "account_sessions", :action => "new"
  map.account_logout '/account/logout', :controller => "account_sessions", :action => "destroy", :method => "delete"
  map.account_registration '/account/signup', :controller => "accounts", :action => "new"
  map.account_instructions '/account/instructions', :controller => "accounts", :action => "instructions"
  map.password_reset '/account/reset', :controller => "password_resets", :action => "new"
  map.verification '/account/verification', :controller => 'accounts', :action => 'verification'
  map.verify_credit_card '/account/verify_credit_card', :controller => 'accounts', :action => 'verify_credit_card', :method => 'post'
  map.secure_verify_credit_card '/account/secure_verify_credit_card', :controller => 'accounts', :action => 'secure_verify_credit_card', :method => 'post'

  map.recovery_confirmation 'mobile_phone_password_resets/:id/recovery_confirmation', :controller => 'mobile_phone_password_resets', :action => 'recovery_confirmation'

  map.users_browse '/users/browse', :controller => 'users', :action => 'index'
  map.users_search '/users/search', :controller => 'users', :action => 'search'

  # Operator user (admin) named routes
  map.operator_login '/operator/login', :controller => "operator_sessions", :action => "new"
  map.operator_logout '/operator/logout', :controller => "operator_sessions", :action => "destroy", :method => "delete"

  map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'
  map.simple_captcha_read '/simple_captcha_read.mp3', :controller => 'simple_captcha_reader', :action => 'simple_captcha_read'


  map.connect '/users/ajax_search', :controller => 'users', :action => 'ajax_search'
  map.connect '/users/find', :controller => 'users', :action => 'find', :method => 'post'

  map.resource :account
  map.resource :account_session
  map.resource :operator_session

  map.resources :configurations
  map.resources :users do |users|
    users.resources :radius_accountings
    users.resources :stats, :only => :show
  end
  map.resources :online_users, :only => :index
  map.resources :operators
  map.resources :password_resets
  map.resources :email_password_resets
  map.resources :mobile_phone_password_resets
  map.resources :stats, :only => [:index, :show], :collection => { :export => :post }

  map.root :account_instructions

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
