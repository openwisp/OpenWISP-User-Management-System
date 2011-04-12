class HouseKeeperWorker < BackgrounDRb::MetaWorker
  set_worker_name :house_keeper_worker

  def create(args = nil)

  end

  def remove_unverified_users()
    User.find(:all, :conditions => [ "verified_at is NULL AND NOT verified" ]).each do |unverified_user|
      if unverified_user.verification_method == Account::VERIFY_BY_MOBILE and
          unverified_user.created_at + Configuration.get('mobile_phone_registration_expire').to_i <= Time.now()
        puts "[#{Time.now()}] User '#{unverified_user.given_name} #{unverified_user.surname}' - (#{unverified_user.username}) didn't validate it's account. I'm going to remove him/her..."
        unverified_user.destroy
      elsif unverified_user.verification_method == Account::VERIFY_BY_CREDIT_CARD and
          unverified_user.created_at + Configuration.get('credit_card_registration_expire').to_i <= Time.now()
        puts "[#{Time.now()}] User '#{unverified_user.given_name} #{unverified_user.surname}' - (#{unverified_user.username}) didn't validate it's account. I'm going to remove him/her..."
        unverified_user.destroy
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

