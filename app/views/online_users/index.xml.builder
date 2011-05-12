xml.instruct!
xml.online_users :type => :array do
  @online_users.each do |online_user|
    xml.online_user do
      xml.username online_user.username

      xml.radius_accounting do
        xml.calling_station_id online_user.radius_accountings.still_open.calling_station_id
      end
    end
  end
end

