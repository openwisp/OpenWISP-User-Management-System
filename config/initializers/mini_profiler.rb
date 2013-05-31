if Rails.env == 'development'
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
  Rack::MiniProfiler.config.position = 'right'
  
  Rack::MiniProfiler.config.skip_paths << "/images/"
  Rack::MiniProfiler.config.skip_paths << "/stylesheets/"
  Rack::MiniProfiler.config.skip_paths << "/javascripts/"
  Rack::MiniProfiler.config.skip_paths << "/favicon.ico"
end