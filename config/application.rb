require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

# in case config.yml has not been created load the default settings
begin
  CONFIG = YAML.load(File.read(File.expand_path('../config.yml', __FILE__)))[Rails.env]
rescue Errno::ENOENT
  CONFIG = YAML.load(File.read(File.expand_path('../config.default.yml', __FILE__)))[Rails.env]
end

CONFIG['mac_address_authentication'] = CONFIG['mac_address_authentication'].nil? ? false : CONFIG['mac_address_authentication']
CONFIG['english'] = CONFIG['english'].nil? ? true : CONFIG['english']
CONFIG['italian'] = CONFIG['italian'].nil? ? true : CONFIG['italian']
CONFIG['spanish'] = CONFIG['spanish'].nil? ? true : CONFIG['spanish']
CONFIG['german'] = CONFIG['german'].nil? ? true : CONFIG['german']
CONFIG['slovenian'] = CONFIG['slovenian'].nil? ? false : CONFIG['slovenian']
CONFIG['furlan'] = CONFIG['furlan'].nil? ? false : CONFIG['furlan']

# checks
CONFIG['check_called_station_id'] = CONFIG['check_called_station_id'].nil? ? { 'between_min' => 10, 'between_max' => 60} : CONFIG['check_called_station_id']

# app root dir and static assets host
CONFIG['root_dir'] = CONFIG['root_dir'].nil? ? '/' : CONFIG['root_dir']
CONFIG['asset_host'] = CONFIG['asset_host'].nil? ? false : CONFIG['asset_host']


module Owums
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{Rails.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Rome'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :it

    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w(jquery jquery_ujs jquery.observe)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [
        :password,
        :password_confirmation,
        :crypted_password,
        :number1,
        :number2,
        :number3,
        :number4,
        :cvv,
        :expiration_month,
        :expiration_year
    ]

    # Force all environments to use the same logger level
    # (by default production uses :info, the others :debug)
    # config.log_level = :debug
  end
end
