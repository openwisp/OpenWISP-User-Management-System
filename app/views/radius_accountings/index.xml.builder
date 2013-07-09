xml.radius_accountings do
  @radius_accountings.each do |radius_accounting|
    xml.radius_accounting do
      xml.rad_acct_id radius_accounting.id
      xml.username radius_accounting.username
      xml.full_name "%s %s" % [radius_accounting.given_name, radius_accounting.surname]
      xml.framed_ip_address radius_accounting.framed_ip_address
      xml.calling_station_id radius_accounting.calling_station_id
      xml.acct_start_time radius_accounting.acct_start_time
      xml.acct_stop_time radius_accounting.acct_stop_time == '0000-00-00 00:00:00' ? nil : radius_accounting.acct_stop_time
      xml.realm radius_accounting.realm
      xml.nas_ip_address radius_accounting.nas_ip_address
      xml.called_station_id radius_accounting.called_station_id
      xml.acct_session_id radius_accounting.acct_session_id
      xml.acct_unique_id radius_accounting.acct_unique_id
      xml.acct_input_octets radius_accounting.acct_input_octets
      xml.acct_output_octets radius_accounting.acct_output_octets
      xml.acct_terminate_cause radius_accounting.acct_terminate_cause
      xml.acct_session_time radius_accounting.acct_session_time
    end
  end
end