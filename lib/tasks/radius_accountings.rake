namespace :radius_accountings do

  task :convert => :environment do
    convert()
  end
  
  task :check => :environment do
    check()
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
    
    count = RadiusAccounting.where(
      'AcctStartTime <= :min AND
      AcctStartTime >= :max AND
      CHAR_LENGTH(CalledStationId) > 17', {
        :min => min,
        :max => max
      }
    ).count
    
    if count <= 0
      e = Exception.new('radius_accountings:convert task not working properly, found 0 records with correctly converted called-station-id.')
      ExceptionNotifier::Notifier.background_exception_notification(e).deliver
      puts 'notified problem'
    else
      puts 'everything ok'
    end
  end
end