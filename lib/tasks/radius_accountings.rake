namespace :radius_accountings do

  task :convert => :environment do
    convert()
  end

  task :check => :environment do
    check()
  end

  task :cleanup_stale => :environment do
    RadiusAccounting.cleanup_stale_radius_accountings
  end

  task :delete_1y_old_sessions => :environment do
    RadiusAccounting.delete_1y_old_sessions
  end

  # converts the attribute "CalledStationId" of radius accounting records which
  # do not contain the mac address of the access point from where the users connected
  # so that they will include this info
  def convert
    converted_sessions = RadiusAccounting.convert_radius_accountings_to_aware
    puts "Converted #{converted_sessions.length} radius sessions"
  end

  # ensures the conversion is working
  # must be put in a cronjob
  def check
    min = (CONFIG['check_called_station_id']['between_min']).minutes.ago
    max = (CONFIG['check_called_station_id']['between_max']).minutes.ago
    options = {:min => min, :max => max}
    where = 'AcctStartTime <= :min AND AcctStartTime >= :max'

    session_count = RadiusAccounting.where(where, options).count
    converted_sessions = RadiusAccounting.where("#{where} AND CHAR_LENGTH(CalledStationId) > 17", options).count

    if session_count > 0 and converted_sessions < 1
      Pony.mail({
        :from => Configuration.get('exception_notification_sender'),
        :to => Configuration.get('exception_notification_recipients'),
        :subject => "#{Configuration.get('exception_notification_email_prefix')} radius_accountings:convert NOT WORKING PROPERLY",
        :body => 'radius_accountings:convert task not working properly, found 0 records with correctly converted called-station-id.',
        :via => :smtp,
        :via_options => Rails.application.config.action_mailer.smtp_settings
      })
      puts 'notified problem'
    else
      puts 'everything ok'
    end
  end
end
