Rake::Task["db:seed"].enhance do
  require 'active_record/fixtures'
  Dir.glob("#{Rails.root}/db/fixtures/*.yml").each do |file|
    puts "Loading db/fixtures/#{File.basename(file)}"
    Fixtures.create_fixtures('db/fixtures', File.basename(file, '.*'))
  end
end
