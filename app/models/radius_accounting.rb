# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class RadiusAccounting < ActiveRecord::Base
  # Legacy !
  set_primary_key "RadAcctId"
  alias_attribute :username, :UserName
  alias_attribute :realm, :Realm
  alias_attribute :acct_session_id, :AcctSessionId
  alias_attribute :acct_unique_id, :AcctUniqueId
  alias_attribute :acct_input_octets, :AcctInputOctets
  alias_attribute :acct_output_octets, :AcctOutputOctets
  alias_attribute :acct_terminate_cause, :AcctTerminateCause
  alias_attribute :nas_ip_address, :NASIPAddress
  alias_attribute :called_station_id, :CalledStationId
  alias_attribute :framed_ip_address, :FramedIPAddress
  alias_attribute :acct_session_time, :AcctSessionTime

  # RadiusAccountings shouldn't be created/modified by Rails
  attr_accessible

  def self.table_name() "radacct" end

  with_options :foreign_key => :UserName, :primary_key => :username do |assoc|
    assoc.belongs_to :account_common
    assoc.belongs_to :account
    assoc.belongs_to :user
  end

  RADIUS_DATE_FORMAT="%Y-%m-%d"
  RADIUS_DATETIME_FORMAT="%Y-%m-%d %H:%M:%S"

  # Class methods

  def self.last_logins(num = 5)
    order("AcctStartTime DESC").limit(num)
  end

  def self.logins_on(date)
    count(:conditions => ["DATE(AcctStartTime) = ?", date.to_s])
  end

  def self.unique_logins_on(date)
    count('UserName', :distinct => true, :conditions => ["DATE(AcctStartTime) = ?", date.to_s])
  end

  def self.logins_from(from, to)
    count('UserName',
          :select => 'AcctStartTime',
          :conditions => [ "DATE(AcctStartTime) >= ? AND DATE(AcctStartTime) <= ?", from, to ],
          :group => "DATE(AcctStartTime)"
    ).map { |on_date, count| [ on_date.to_datetime.to_i * 1000, count.to_i ] }
  end

  def self.unique_logins_from(from, to)
    count('UserName',
          :conditions => [ "DATE(AcctStartTime) >= ? AND DATE(AcctStartTime) <= ?", from, to ],
          :group => "DATE(AcctStartTime)",
          :distinct => true
    ).map { |on_date, count| [ on_date.to_datetime.to_i * 1000, count.to_i ] }
  end

  def self.logins_each_day(from, to)
    [ logins_from(from, to), unique_logins_from(from, to) ]
  end

  def self.traffic_in_on(date)
    sum('AcctInputOctets', :conditions => "DATE(AcctStartTime) = '#{date.to_s}'")
  end

  def self.traffic_out_on(date)
    sum('AcctOutputOctets', :conditions => "DATE(AcctStartTime) = '#{date.to_s}'")
  end

  def self.traffic_on(date)
    traffic_in_on(date) + traffic_out_on(date)
  end

  def self.traffic_in(from, to)
    sum('AcctInputOctets',
        :conditions => [ "DATE(AcctStartTime) >= ? AND DATE(AcctStartTime) <= ?", from, to ],
        :group => "DATE(AcctStartTime)"
    ).map { |on_date, traffic| [ on_date.to_datetime.to_i * 1000, traffic.to_i ] }
  end

  def self.traffic_out(from, to)
    sum('AcctOutputOctets',
        :conditions => [ "DATE(AcctStartTime) >= ? AND DATE(AcctStartTime) <= ?", from, to ],
        :group => "DATE(AcctStartTime)"
    ).map { |on_date, traffic| [ on_date.to_datetime.to_i * 1000, traffic.to_i ] }
  end

  def self.traffic(from, to)
    sum('AcctInputOctets + AcctOutputOctets',
        :conditions => [ "DATE(AcctStartTime) >= ? AND DATE(AcctStartTime) <= ?", from, to ],
        :group => "DATE(AcctStartTime)"
    ).map { |on_date, traffic| [ on_date.to_datetime.to_i * 1000, traffic.to_i ] }
  end

  def self.traffic_each_day(from, to)
    [ traffic(from, to), traffic_in(from, to), traffic_out(from, to) ]
  end

  def self.still_open
    where("AcctStopTime = '0000-00-00 00:00:00' OR AcctStopTime is NULL").order("AcctStartTime DESC")
  end

  def self.on_day(day)
    where("AcctStopTime = '0000-00-00 00:00:00' OR AcctStopTime is NULL OR DATE(AcctStopTime) >= ?", day.strftime(RADIUS_DATE_FORMAT)).where("DATE(AcctStartTime) <= ?", day.strftime(RADIUS_DATE_FORMAT))
  end

  def self.find_by_username(username)
    find_by_UserName(username)
  end
  
  def self.with_full_name
    select("radacct.*, users.username, users.given_name, users.surname").joins("LEFT OUTER JOIN users ON radacct.UserName = users.username")
  end
  
  def self.find_unaware_radius_accountings
    # returns radius accounting records which do not have the format
    # <mac_address_of_ap_from_where_user_accessed>:<captive_portal_interface>
    # and are still connected
    where("CHAR_LENGTH(CalledStationId) <= 17 AND AcctStopTime IS NULL")
  end
  
  def self.convert_radius_accountings_to_aware
    # convert radius accounting CalledStationId attribute so that it's in the format:
    # <mac_address_of_ap_from_where_user_accessed>:<captive_portal_interface>
    ra = self.find_unaware_radius_accountings()
    modified_records = []
    
    ra.each do |accounting|
      user_mac = accounting.calling_station_id
      ap_mac = AssociatedUser.access_point_mac_address_by_user_mac_address(user_mac) rescue next
      
      new_called_station_id = "%s:%s" % [
        ap_mac.upcase.gsub(':', '-'),
        accounting.called_station_id.gsub(':', '-').gsub(' ', '')
      ]
      
      accounting.called_station_id = new_called_station_id
      accounting.save
      modified_records.push(accounting)
    end
    
    return modified_records
  end

  # Accessors

  ## Read

  def acct_start_time
    if Configuration.get('local_time_radius_accounting') == 'true'
      self.AcctStartTime - Time.now().utc_offset
    else
      self.AcctStartTime
    end
  end

  def acct_stop_time
    if Configuration.get('local_time_radius_accounting') == 'true'
      self.AcctStopTime.nil? ? nil : self.AcctStopTime - Time.now().utc_offset
    else
      self.AcctStopTime
    end
  end

  def calling_station_id
    # Normalize mac addresses output
    self.CallingStationId.downcase.gsub "-", ":"
  end

  # Utilities

  def traffic_out_mega
    # Convert bytes to megabytes (1048576 = 1024*1024)
    sprintf "%.2f", self.AcctOutputOctets/1048576.0
  end

  def traffic_in_mega
    # Convert bytes to megabytes (1048576 = 1024*1024)
    sprintf "%.2f", self.AcctInputOctets/1048576.0
  end
end
