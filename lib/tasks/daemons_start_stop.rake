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

namespace :daemons do

  def backgroundrb_status
    print 'BackgrounDRb: '
    %x[bundle exec #{Rails.root}/script/backgroundrb status]
    puts $? == 0 ? 'running...' : 'not running...'
    $?
  end

  def backgroundrb_start
    puts 'Starting BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb start]
    $?
  end

  def backgroundrb_stop
    puts 'Stopping BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb stop]
    $?
  end

  def sip_busy_machine_status
    print 'MobilePhoneSipBusyMachine: '
    sip_status = %x[bundle exec #{Rails.root}/lib/daemons/mobile_phone_sip_busy_machine_ctl status]
    puts sip_status =~ /running \[pid .\d+\]/ ? 'running...' : 'not running...'
    sip_status =~ /no instances running/
  end

  def sip_busy_machine_start
    puts 'Starting MobilePhoneSipBusyMachine...'
    %x[bundle exec #{Rails.root}/lib/daemons/mobile_phone_sip_busy_machine_ctl start]
    $?
  end

  def sip_busy_machine_stop
    puts 'Stopping MobilePhoneSipBusyMachine...'
    %x[bundle exec #{Rails.root}/lib/daemons/mobile_phone_sip_busy_machine_ctl stop]
    $?
  end

  desc "Start deamons required to run OWUMS"
  task :start => :environment do
    backgroundrb_start
    sip_busy_machine_start

    Rake::Task['daemons:status'].execute
  end

  desc "Stop deamons required to run OWUMS"
  task :stop => :environment do
    backgroundrb_stop
    sip_busy_machine_stop

    Rake::Task['daemons:status'].execute
  end

  desc "Restart deamons required to run OWUMS"
  task :restart => :environment do
    puts 'Restarting OWUMS daemons...'

    begin
      backgroundrb_stop
      sleep 1
    end while backgroundrb_status == 0

    begin
      sip_busy_machine_stop
      sleep 1
    end while sip_busy_machine_status == 0

    backgroundrb_start
    sip_busy_machine_start

    Rake::Task['daemons:status'].execute
  end

  desc "Status of daemons required to run OWUMS"
  task :status => :environment do
    exit(1) if backgroundrb_status != 0 && sip_busy_machine_status
  end
end
