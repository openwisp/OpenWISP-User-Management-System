CONFIG['omniauth_providers'] = []
CONFIG['social_login_enabled'] = (Configuration.get("social_login_enabled", "false") == "true") rescue false
CONFIG['ssl_ca_path'] = CONFIG['ssl_ca_path'].nil? ? '/usr/lib/ssl/certs' : CONFIG['ssl_ca_path']

# ensure feature enabled during automated tests
if RAILS_ENV == 'test'
  CONFIG['social_login_enabled'] = true
end

if CONFIG['social_login_enabled']
  Rails.application.config.middleware.use OmniAuth::Builder do
    facebook_id = Configuration.get('social_login_facebook_id', '')
    facebook_secret = Configuration.get('social_login_facebook_secret', '')
    google_id = Configuration.get('social_login_google_id', '')
    google_secret = Configuration.get('social_login_google_secret', '')

    if facebook_id != '' and facebook_secret != ''
      provider :facebook, facebook_id, facebook_secret,
               :scope => 'email,user_birthday,user_location',
               :display => 'page',
               :client_options => { :ssl => { :ca_path => CONFIG['ssl_ca_path'] }}

      CONFIG['omniauth_providers'].push(:facebook)
    end

    if google_id != '' and google_secret != ''
      provider :google_oauth2, google_id, google_secret,
               :scope => 'plus.me,userinfo.email',
               :client_options => { :ssl => { :ca_path => CONFIG['ssl_ca_path'] }}

      CONFIG['omniauth_providers'].push(:google_oauth2)
    end
  end
end
