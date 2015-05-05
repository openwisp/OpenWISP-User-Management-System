if Configuration.get("social_login_enabled", "false") == "true"
  Rails.application.config.middleware.use OmniAuth::Builder do
    facebook_id = Configuration.get('social_login_facebook_id', '')
    facebook_secret = Configuration.get('social_login_facebook_secret', '')
    google_id = Configuration.get('social_login_google_id', '')
    google_secret = Configuration.get('social_login_google_secret', '')

    if facebook_id and facebook_secret
      provider :facebook, facebook_id, facebook_secret,
               :scope => 'email,user_birthday,user_location',
               :display => 'page'
    end

    if google_id and google_secret
      provider :google_oauth2, google_id, google_secret,
               :scope => 'plus.login'
    end
  end
end
