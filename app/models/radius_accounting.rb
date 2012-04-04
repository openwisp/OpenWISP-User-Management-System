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
  alias_attribute :calling_station_id, :CallingStationId
  alias_attribute :called_station_id, :CalledStationId
  alias_attribute :framed_ip_address, :FramedIPAddress
  alias_attribute :acct_session_time, :AcctSessionTime

  def self.table_name() "radacct" end

  with_options :foreign_key => :UserName, :primary_key => :username do |assoc|
    assoc.belongs_to :account_common
    assoc.belongs_to :account
    assoc.belongs_to :user
  end

  # Class methods

  def self.last_logins(num = 5)
    order("AcctStartTime DESC").limit(num)
  end

  def self.logins_on(date)
    count(:conditions => "DATE(AcctStartTime) = '#{date.to_s}'")
  end

  def self.unique_logins_on(date)
    count('UserName', :distinct => true, :conditions => "DATE(AcctStartTime) = '#{date.to_s}'")
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
