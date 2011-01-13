# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'custom_logger'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "authlogic", :version => '2.1.3'
  config.gem "be9-acl9", :source => "http://gems.github.com", :lib => "acl9", :version => '0.11.0'
  config.gem "chronic", :version => '0.2.3'
  config.gem "packet", :version => '0.1.15'
  config.gem 'will_paginate', :version => '2.3.11', :source => 'http://gemcutter.org'
  config.gem 'rmagick', :version => '2.12.2', :lib => 'RMagick'
  config.gem 'fleximage', :version => '1.0.4'
  config.gem 'daemons', :version => '1.0.10'
  
  config.action_controller.session_store = :active_record_store
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Rome'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = 'it'
  
  # initializing custom logger
  config.logger = CustomLogger.new(config.log_path, config.log_level)

end

if ENV['RAILS_ENV'] == 'production'
  if !(system 'echo "hello" | text2wave | lame - - >/dev/null 2>&1')
    raise "Missing 'lame' or festival 'text2wave' command!  (on Ubuntu run the following command as root: 'apt-get install lame festival festvox-italp16k festvox-rablpc16k')"
  elsif !(system 'echo "ciao" | text2wave -eval "(language_italian)" >/dev/null 2>&1')
    raise "Missing italian festvox! (on Ubuntu run the following command as root: 'apt-get install festival festvox-italp16k festvox-rablpc16k')"
  end
end

ExceptionNotifier.exception_recipients = [ 'root@localhost' ]
ExceptionNotifier.sender_address = 'root@localhost'
ExceptionNotifier.email_prefix = "[OWUMS] "
ExceptionNotifier.sections.unshift("owums")

