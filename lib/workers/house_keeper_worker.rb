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

class HouseKeeperWorker < BackgrounDRb::MetaWorker
  set_worker_name :house_keeper_worker

  def create(args = nil)

  end

  def remove_unverified_users
    User.unverified.each do |user|
      if user.verification_expired?
        # if verified by visa user just disable
        if user.verify_with_gestpay? and user.active and Configuration.get('gestpay_webservice_method') != 'verification' and !user.credit_card_info.nil? and !user.credit_card_info.empty?
          puts "[#{Time.now()}] User '#{user.given_name} #{user.surname}' - (#{user.username}) didn't validate its account but it's a verified by visa attempt. Disabling it..."
          user.active = false
          user.save!
        # else delete
        else
          puts "[#{Time.now()}] User '#{user.given_name} #{user.surname}' - (#{user.username}) didn't validate its account. I'm going to remove him/her..."
          user.destroy
        end
      end
    end
  end

  def remove_disabled_users
    User.disabled.each do |user|
      # do not remove verified by visa disabled users
      if user.registration_expired? and not (user.verify_with_gestpay? and !user.credit_card_info.nil? and !user.credit_card_info.empty?)
        puts "[#{Time.now()}] User '#{user.given_name} #{user.surname}' - (#{user.username}) was disabled for a long time. I'm going to remove him/her..."
        user.destroy
      end
    end
  end

  def external_command_for_new_accounts
    command = Configuration.get('external_command_for_new_accounts')

    unless command.blank?
      new_accounts = User.registered_yesterday

      new_accounts.each do |account|
        puts "[#{Time.now()}] Executing external command for account '#{account.given_name} #{account.surname}' - (#{account.username})"

        begin
          fd = IO.popen(command, "w")
          fd.puts(account.to_xml)
          puts "[#{Time.now()}] External command exit status: " + $?.exitstatus.to_s
          fd.close
        rescue
          puts "[#{Time.now()}] Problem executing external command '#{command}'"
        end
      end
    end
  end

  def remove_stale_sessions
    puts "[#{Time.now()}] Removing stale sessions record..."
    ActiveRecord::SessionStore::Session.destroy_all("updated_at < '#{1.month.ago.to_s(:db)}'")
  end

  def remove_stale_bdrbs
    puts "[#{Time.now()}] Removing stale bdrbs jobs..."
    jobs = BdrbJobQueue.destroy_all("finished_at < '#{2.month.ago.to_s(:db)}'")
    jobs.each { |j| $stderr.puts "* Worker name: #{j.worker_name} - Method: #{j.worker_method} - Key: #{j.job_key} DESTROYED" }
  end

end

