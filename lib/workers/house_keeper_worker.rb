class HouseKeeperWorker < BackgrounDRb::MetaWorker
  set_worker_name :house_keeper_worker

  def create(args = nil)

  end

  def remove_unverified_users
    User.unverified.each do |user|
      if user.verification_expired?
        puts "[#{Time.now()}] User '#{user.given_name} #{user.surname}' - (#{user.username}) didn't validate it's account. I'm going to remove him/her..."
        user.destroy
      end
    end
  end

  def remove_disabled_users
    User.disabled.each do |user|
      if user.registration_expired?
        puts "[#{Time.now()}] User '#{user.given_name} #{user.surname}' - (#{user.username}) didn't validate it's account. I'm going to remove him/her..."
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
          fd.puts(account.to_xml( :except => [ :crypted_password, :password_salt, :perishable_token, :persistence_token, :single_access_token ] ))
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

