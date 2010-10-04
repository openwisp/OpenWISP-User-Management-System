# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_newregsystem_session',
  :secret      => '2d562fdda9f0f6492cd1ed3a2102e69a05dc79e26ae3ff41e320567c3a7ee78ba9f96290ae2f19b3f5671c6693b4d1255b3c332bd684779abed7c955f6dc5a45'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
