namespace :daemons do
  desc "Start deamons required to run OWUMS"
  task :start => :environment do
    puts 'Starting BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb start]

    puts 'Starting MobilePhoneSipBusyMachine...'
    %x[bundle exec #{Rails.root}/lib/daemons/mobile_phone_sip_busy_machine_ctl start]

    Rake::Task['daemons:status'].execute
  end

  desc "Stop deamons required to run OWUMS"
  task :stop => :environment do
    puts 'Stopping BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb stop]

    puts 'Stopping MobilePhoneSipBusyMachine...'
    %x[bundle exec #{Rails.root}/lib/daemons/mobile_phone_sip_busy_machine_ctl stop]

    Rake::Task['daemons:status'].execute
  end

  desc "Restart deamons required to run OWUMS"
  task :restart => :environment do
    puts 'Restarting OWUMS daemons...'
    Rake::Task['daemons:stop'].execute
    Rake::Task['daemons:start'].execute
  end

  desc "Status of daemons required to run OWUMS"
  task :status => :environment do
    print 'BackgrounDRb: '
    %x[bundle exec #{Rails.root}/script/backgroundrb status]
    puts $? == 0 ? 'running...' : 'not running...'

    print 'MobilePhoneSipBusyMachine: '
    out = %x[bundle exec #{Rails.root}/lib/daemons/mobile_phone_sip_busy_machine_ctl status]
    puts out =~ /running \[pid .\d+\]/ ? 'running...' : 'not running...'
  end
end