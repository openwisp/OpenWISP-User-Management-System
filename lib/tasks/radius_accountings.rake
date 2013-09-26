namespace :radius_accountings do

  task :convert => :environment do
    convert
  end

  def convert
    # converts the attribute "CalledStationId" of radius accounting records which
    # do not contain the mac address of the access point from where the users connected
    # so that they will include this info
    converted_sessions = RadiusAccounting.convert_radius_accountings_to_aware
    puts "Converted #{converted_sessions.length} radius sessions"
  end
end