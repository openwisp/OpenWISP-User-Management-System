namespace :db do
  namespace :test do
    task :prepare => :environment do
      Rake::Task["db:fixtures:load"].invoke
    end
  end
end
