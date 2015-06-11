if CONFIG['sentry_dsn']
  Raven.configure do |config|
    config.dsn = CONFIG['sentry_dsn']
  end
end
