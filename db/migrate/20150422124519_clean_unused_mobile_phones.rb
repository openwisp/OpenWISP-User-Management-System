class CleanUnusedMobilePhones < ActiveRecord::Migration
  def self.up
    # this will run the before_validation check and clean up
    # users which have a mobile_suffix and mobile_prefix filled even if not needed
    accounts = Account.where('mobile_suffix <> "" AND mobile_suffix IS NOT NULL AND verification_method <> "mobile_phone"')
    accounts.all.each do |user|
      if user.valid?
        user.save
      else
        puts "Problems with user: #{user.username}, id: #{user.id},\nerrors: #{user.errors}\n\n"
      end
    end
  end

  def self.down
  end
end
