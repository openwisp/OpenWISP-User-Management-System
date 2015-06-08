CONFIG['gestpay_enabled'] = Configuration.get('gestpay_enabled') == 'true' rescue 'false'

# ensure feature enabled during automated tests
if RAILS_ENV == 'test'
  CONFIG['gestpay_enabled'] = true
end
