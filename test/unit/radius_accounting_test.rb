require 'test_helper'

class RadiusAccountingTest < ActiveSupport::TestCase
  
  def _create_sessions(n, destroy_all=true, progressive_octets=false)
    if destroy_all
      RadiusAccounting.destroy_all
    end
    
    in_octets = 3000000
    out_octets = 6000000
    
    (1..n).each do |c|
      if progressive_octets
        in_octets = c * 1000
        out_octets = c * 2000
      end
      ra = RadiusAccounting.new()
      ra.acct_session_id = SecureRandom.hex[0, 17]
      ra.acct_unique_id = SecureRandom.hex[0, 16]
      ra.UserName = SecureRandom.hex
      ra.Realm = nil
      ra.nas_ip_address = '192.168.1.1'
      ra.NASPortId = 0
      ra.NASPortType = 'Ethernet'
      ra.AcctStartTime = c.days.ago.change(:hour => 8, :minutes => 0)
      ra.AcctStopTime = c.days.ago.change(:hour => 11, :minutes => 0)
      ra.acct_session_time = 3.hours.seconds.to_i
      ra.AcctAuthentic = 'RADIUS'
      ra.ConnectInfo_start = ''
      ra.ConnectInfo_stop = ''
      ra.acct_input_octets = in_octets
      ra.acct_output_octets = out_octets
      ra.called_station_id = '00-26-B9-75-F2-1D:br-dwifi'
      ra.acct_terminate_cause = 'Session-Timeout'
      ra.ServiceType = 'Login-User'
      ra.FramedProtocol = ''
      ra.framed_ip_address = "172.20.55.#{rand(254-2)}"
      ra.AcctStartDelay = 0
      ra.AcctStopDelay = 0
      ra.save!
    end
  end
  
  test "create_sessions" do
    _create_sessions(10)
    assert_equal 10, RadiusAccounting.count
  end
  
  test "create_sessions progressive" do
    _create_sessions(10, true, true)
    assert_equal 10, RadiusAccounting.count
    ra = RadiusAccounting.all
    
    # ensure _create_sessions with progressive octets works as expected
    ra.each_with_index do |r, i|
      c = i+1
      assert_equal c*1000, r.acct_input_octets
      assert_equal c*2000, r.acct_output_octets
    end
  end
  
  test "logins_on" do
    _create_sessions(1)
    assert_equal 1, RadiusAccounting.logins_on(1.days.ago.to_date)
  end
  
  test "unique_logins_on" do
    _create_sessions(1)
    assert_equal 1, RadiusAccounting.unique_logins_on(1.days.ago.to_date)
    
    RadiusAccounting.all.each do |ra|
      new = RadiusAccounting.new()
      new.acct_session_id = SecureRandom.hex[0, 17]
      new.acct_unique_id = SecureRandom.hex[0, 16]
      new.UserName = ra.UserName
      new.Realm = nil
      new.nas_ip_address = '192.168.1.1'
      new.NASPortId = 0
      new.NASPortType = 'Ethernet'
      new.AcctStartTime = ra.acct_start_time.change(:hour => 12, :minutes => 0)
      new.AcctStopTime = ra.acct_stop_time.change(:hour => 15, :minutes => 0)
      new.acct_session_time = 3.hours.seconds.to_i
      new.AcctAuthentic = 'RADIUS'
      new.ConnectInfo_start = ''
      new.ConnectInfo_stop = ''
      new.acct_input_octets = 3000000
      new.acct_output_octets = 6000000
      new.called_station_id = '00-26-B9-75-F2-1D:br-dwifi'
      new.acct_terminate_cause = 'Session-Timeout'
      new.ServiceType = 'Login-User'
      new.FramedProtocol = ''
      new.framed_ip_address = "172.20.55.#{rand(254-2)}"
      new.AcctStartDelay = 0
      new.AcctStopDelay = 0
      new.XAscendSessionSvrKey = nil
      new.save!
    end
    
    assert_equal 2, RadiusAccounting.count
    assert_equal 1, RadiusAccounting.unique_logins_on(1.days.ago.to_date)
  end
  
  test "logins_from" do
    _create_sessions(10)
    
    from = 11.days.ago
    to = Date.today
    
    l = RadiusAccounting.logins_from(from, to)
    
    assert_equal 10, l.length
    assert_equal Array, l.class
    assert_equal 2, l[0].length
    assert_equal Array, l[0].class
    
    # ensure date format is the one we expect
    assert_equal 1, l[0][1]
    assert_equal RadiusAccounting.first.acct_start_time.to_date.to_datetime.to_i * 1000, l[-1][0]
    assert_equal RadiusAccounting.last.acct_start_time.to_date.to_datetime.to_i * 1000, l[0][0]
    
    l = RadiusAccounting.logins_from(from, to, '00-26-B9-75-F2-1D')
    assert_equal 10, l.length
    
    l = RadiusAccounting.logins_from(from, to, '00-00-00-00-00-00')
    assert_equal 0, l.length
    
    # in between
    _create_sessions(10)
    from = 6.days.ago
    to = 2.days.ago
    l = RadiusAccounting.logins_from(from, to)
    
    assert_equal 4, l.length
    assert_equal 1, l[0][1]
    
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{5.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, l[0][0]
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{2.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, l[-1][0]
  end
  
  test "unique_logins_from" do
    _create_sessions(10)
    
    RadiusAccounting.all.each do |ra|
      new = RadiusAccounting.new()
      new.acct_session_id = SecureRandom.hex[0, 17]
      new.acct_unique_id = SecureRandom.hex[0, 16]
      new.UserName = ra.UserName
      new.Realm = nil
      new.nas_ip_address = '192.168.1.1'
      new.NASPortId = 0
      new.NASPortType = 'Ethernet'
      new.AcctStartTime = ra.acct_start_time.change(:hour => 12, :minutes => 0)
      new.AcctStopTime = ra.acct_stop_time.change(:hour => 15, :minutes => 0)
      new.acct_session_time = 3.hours.seconds.to_i
      new.AcctAuthentic = 'RADIUS'
      new.ConnectInfo_start = ''
      new.ConnectInfo_stop = ''
      new.acct_input_octets = 3000000
      new.acct_output_octets = 6000000
      new.called_station_id = '00-26-B9-75-F2-1D:br-dwifi'
      new.acct_terminate_cause = 'Session-Timeout'
      new.ServiceType = 'Login-User'
      new.FramedProtocol = ''
      new.framed_ip_address = "172.20.55.#{rand(254-2)}"
      new.AcctStartDelay = 0
      new.AcctStopDelay = 0
      new.XAscendSessionSvrKey = nil
      new.save!
    end
    
    from = 11.days.ago
    to = Date.today
    
    l = RadiusAccounting.logins_from(from, to)
    # we expect 20 total logins
    assert_equal 20, RadiusAccounting.count
    # we expect 2 logins
    assert_equal 2, l[0][1]
    
    l = RadiusAccounting.unique_logins_from(from, to)
    
    assert_equal 10, l.length
    assert_equal Array, l.class
    assert_equal 2, l[0].length
    assert_equal Array, l[0].class
    
    # we expect 1 unique login
    assert_equal 1, l[0][1]
    assert_equal 1, l[1][1]
    
    # ensure date format is the one we expect
    assert_equal RadiusAccounting.first.acct_start_time.to_date.to_datetime.to_i * 1000, l[-1][0]
    assert_equal RadiusAccounting.last.acct_start_time.to_date.to_datetime.to_i * 1000, l[0][0]
    
    l = RadiusAccounting.unique_logins_from(from, to, '00-26-B9-75-F2-1D')
    assert_equal 10, l.length
    
    l = RadiusAccounting.unique_logins_from(from, to, '00-00-00-00-00-00')
    assert_equal 0, l.length
    
    # in between
    _create_sessions(10)
    from = 6.days.ago
    to = 2.days.ago
    l = RadiusAccounting.unique_logins_from(from, to)
    
    assert_equal 4, l.length
    assert_equal 1, l[0][1]
    
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{5.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, l[0][0]
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{2.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, l[-1][0]
  end
  
  test "traffic_in_on" do
    _create_sessions(1)
    assert_equal 3000000, RadiusAccounting.traffic_in_on(1.days.ago.to_date)
    
    _create_sessions(1, false)
    assert_equal 6000000, RadiusAccounting.traffic_in_on(1.days.ago.to_date)
    
    # use a different value for octets_in and octets_out each day
    _create_sessions(10, true, true)
    # ensure the different values on different days are those we expect
    (1..10).each do |n|
      assert_equal 1000*n, RadiusAccounting.traffic_in_on(n.days.ago.to_date)
    end
  end
  
  test "traffic_out_on" do
    _create_sessions(1)
    assert_equal 6000000, RadiusAccounting.traffic_out_on(1.days.ago.to_date)
    
    _create_sessions(1, false)
    assert_equal 12000000, RadiusAccounting.traffic_out_on(1.days.ago.to_date)
    
    # use a different value for octets_in and octets_out each day
    _create_sessions(10, true, true)
    # ensure the different values on different days are those we expect
    (1..10).each do |n|
      assert_equal 2000*n, RadiusAccounting.traffic_out_on(n.days.ago.to_date)
    end
  end
  
  test "traffic_on" do
    _create_sessions(1)
    assert_equal 6000000+3000000, RadiusAccounting.traffic_on(1.days.ago.to_date)
    
    _create_sessions(1, false)
    assert_equal (6000000 + 3000000) * 2, RadiusAccounting.traffic_on(1.days.ago.to_date)
    
    # use a different value for octets_in and octets_out each day
    _create_sessions(10, true, true)
    # ensure the different values on different days are those we expect
    (1..10).each do |n|
      assert_equal 3000*n, RadiusAccounting.traffic_on(n.days.ago.to_date)
    end
  end
  
  test "traffic_in" do
    _create_sessions(10)
    
    from = 11.days.ago
    to = Date.today
    
    t = RadiusAccounting.traffic_in(from, to)
    
    assert_equal 10, t.length
    assert_equal Array, t.class
    assert_equal 2, t[0].length
    assert_equal Array, t[0].class
    
    assert_equal 3000000, t[0][1]
    # ensure date format is the one we expect
    assert_equal RadiusAccounting.first.acct_start_time.to_date.to_datetime.to_i * 1000, t[-1][0]
    assert_equal RadiusAccounting.last.acct_start_time.to_date.to_datetime.to_i * 1000, t[0][0]
    
    _create_sessions(10, false)
    _create_sessions(10, false)
    t = RadiusAccounting.traffic_in(from, to)
    
    assert_equal 10, t.length
    # expect the first value multiplied for 3 3
    assert_equal 9000000, t[0][1]
    
    # in between
    _create_sessions(10)
    from = 6.days.ago
    to = 2.days.ago
    t = RadiusAccounting.traffic_in(from, to)
    
    assert_equal 4, t.length
    assert_equal 3000000, t[0][1]
    
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{5.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, t[0][0]
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{2.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, t[-1][0]
  end
  
  test "traffic_out" do
    _create_sessions(10)
    
    from = 11.days.ago
    to = Date.today
    
    t = RadiusAccounting.traffic_out(from, to)
    
    assert_equal 10, t.length
    assert_equal Array, t.class
    assert_equal 2, t[0].length
    assert_equal Array, t[0].class
    
    assert_equal 6000000, t[0][1]
    # ensure date format is the one we expect
    assert_equal RadiusAccounting.first.acct_start_time.to_date.to_datetime.to_i * 1000, t[-1][0]
    assert_equal RadiusAccounting.last.acct_start_time.to_date.to_datetime.to_i * 1000, t[0][0]
    
    _create_sessions(10, false)
    _create_sessions(10, false)
    t = RadiusAccounting.traffic_out(from, to)
    
    assert_equal 10, t.length
    # expect the first value multiplied for 3 3
    assert_equal 18000000, t[0][1]
    
    # in between
    _create_sessions(10)
    from = 6.days.ago
    to = 2.days.ago
    t = RadiusAccounting.traffic_out(from, to)
    
    assert_equal 4, t.length
    assert_equal 6000000, t[0][1]
    
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{5.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, t[0][0]
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{2.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, t[-1][0]
  end
  
  test "traffic" do
    _create_sessions(10)
    
    from = 11.days.ago
    to = Date.today
    
    t = RadiusAccounting.traffic(from, to)
    
    assert_equal 10, t.length
    assert_equal Array, t.class
    assert_equal 2, t[0].length
    assert_equal Array, t[0].class
    
    assert_equal 6000000 + 3000000, t[0][1]
    # ensure date format is the one we expect
    assert_equal RadiusAccounting.first.acct_start_time.to_date.to_datetime.to_i * 1000, t[-1][0]
    assert_equal RadiusAccounting.last.acct_start_time.to_date.to_datetime.to_i * 1000, t[0][0]
    
    _create_sessions(10, false)
    _create_sessions(10, false)
    t = RadiusAccounting.traffic(from, to)
    
    assert_equal 10, t.length
    # expect the first value multiplied for 3 3
    assert_equal (6000000 + 3000000) * 3, t[0][1]
    
    # in between
    _create_sessions(10)
    from = 6.days.ago
    to = 2.days.ago
    t = RadiusAccounting.traffic(from, to)
    
    assert_equal 4, t.length
    assert_equal 9000000, t[0][1]
    
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{5.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, t[0][0]
    assert_equal RadiusAccounting.where("DATE(AcctStartTime) = '#{2.days.ago.to_date}'")[0].acct_start_time.to_date.to_datetime.to_i * 1000, t[-1][0]
  end
  
  test "on_day" do
    _create_sessions(10)
     
    (1..10).each do |n|
      assert_equal 1, (RadiusAccounting.on_day(n.days.ago.to_date)).length
    end
    
    _create_sessions(10, false)
    (1..10).each do |n|
      assert_equal 2, (RadiusAccounting.on_day(n.days.ago.to_date)).length
    end
  end
end
