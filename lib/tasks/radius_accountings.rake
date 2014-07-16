namespace :radius_accountings do

  task :convert => :environment do
    convert()
  end
  
  task :check => :environment do
    check()
  end
  
  task :cleanup_stale => :environment do
    cleanup_stale()
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
  
  def cleanup_stale
    # retrieve stale sessions
    sessions = RadiusAccounting.where("(AcctStopTime IS NULL OR AcctStopTime = '0000-00-00 00:00:00') AND AcctStartTime <= (NOW() - INTERVAL 3 DAY)")
    
    recalculated = 0
    invalid = 0
    
    sessions.each do |ra|
      # cool, we have the session time
      if ra.AcctSessionTime > 0
        # let's recalculate the stop time
        ra.AcctStopTime = ra.acct_start_time + ra.AcctSessionTime
        # leave a mark so it's recognized
        ra.AcctTerminateCause = 'OWUMS-Stale-Recalculated'
        # increment
        recalculated += 1
      # not cool
      else
        # this is invalid, we mark it as closed but we do so in a way that we can clearly see that the session is invalid
        ra.AcctStopTime = ra.AcctStartTime
        ra.AcctTerminateCause = 'OWUMS-Stale-Invalid'
        invalid += 1
      end
      ra.save
    end
    puts "[#{Date.today}]"
    puts "OWUMS-Stale-Recalculated #{recalculated}"
    puts "OWUMS-Stale-Invalid #{invalid}\n\n"
  end
end