xml.radius_accountings do
  @radius_accountings.each do |radius_accounting|
    xml.radius_accounting do
      xml.acct_start_time radius_accounting.acct_start_time
      xml.acct_stop_time radius_accounting.acct_stop_time == '0000-00-00 00:00:00' ? nil : radius_accounting.acct_stop_time
      xml.realm radius_accounting.realm
      xml.nas_ip_address radius_accounting.nas_ip_address
      xml.acct_session_id radius_accounting.acct_session_id
      xml.acct_unique_id radius_accounting.acct_unique_id
      xml.acct_input_octets radius_accounting.acct_input_octets
      xml.acct_output_octets radius_accounting.acct_output_octets
      xml.acct_terminate_cause radius_accounting.acct_terminate_cause
      xml.acct_session_time radius_accounting.acct_session_time
    end
  end
end