class CleanUnusedMobilePhones < ActiveRecord::Migration
  def self.up
    # this will run the before_validation check and clean up
    # users which have a mobile_suffix and mobile_prefix filled even if not needed
    Account.all.each do |user|
      user.save!
    end
  end

  def self.down
  end
end
