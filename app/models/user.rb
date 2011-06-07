# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2010 CASPUR (Davide Guerri d.guerri@caspur.it)
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

class User < AccountCommon

  # Authlogic
  acts_as_authentic do |c|
    c.maintain_sessions = false
  end


  self.before_validation { |record|
    # Cleaning up unused fields... just in case..

    if record.verify_with_document?
      record.mobile_prefix = nil
      record.mobile_suffix = nil
    elsif record.verify_with_mobile_phone?
      record.image_file_data = nil
    end
  }


  # Validations
  # # Allowing nil to avoid duplicate error notification (password field is already validated by Authlogic)
  validates_inclusion_of :verification_method, :in => VERIFICATION_METHODS,
    :if => Proc.new{|user| user.new_record? }
  validates_inclusion_of :verification_method, :in => [VERIFICATION_METHODS, SELFVERIFICATION_METHODS].flatten,
    :if => Proc.new{|user| !user.new_record? }


  has_many :radius_checks,  :as => :radius_entity, :dependent => :destroy
  has_many :radius_replies, :as => :radius_entity, :dependent => :destroy


  # Class methods

  def self.last_registered(num = 5)
    User.find(:all, :order => "created_at DESC", :limit => num)
  end

  # Class Method:
  #   top_traffic()
  # Description:
  #   Returns most active (traffic pov) users
  # Input:
  #   Max number of users
  # Output
  #   Hash { :user => <User model instance>,  :total_traffic => <total traffic (bytes)> }
  def self.top_traffic(num = 5)
    top = RadiusAccounting.all(:select => 'UserName',
                               :group => :UserName,
                               :order => 'sum(AcctInputOctets + AcctOutputOctets) DESC',
                               :limit => num)
    ret = []
    top.each do |t|
        user = User.find_by_username(t.UserName) # See the above select
        ret.push(user) unless user.nil?
    end

    ret
  end

  def self.find_all_by_user_phone_or_mail(query)
    find(:all, :conditions => [ "username = ? OR CONCAT(mobile_prefix,mobile_suffix) = ? OR email = ?" ] + [query]*3)
  end

  def self.registered_each_day(from, to)
    (from..to).map do |that_day|
      [that_day.to_datetime.to_i * 1000, User::registered_on(that_day)]
    end
  end

  def self.registered_on(date)
    count :conditions => "Date(verified_at) <= '#{date.to_s}'"
  end

  def self.registered_yesterday
    find(:all, :conditions => { :created_at => 1.day.ago..DateTime.now })
  end

  def self.unverified
    find(:all, :conditions => [ "verified_at is NULL AND NOT verified" ])
  end

  def self.disabled
    find(:all, :conditions => [ "verified_at is NOT NULL AND NOT verified" ])
  end

  # Utilities

  def total_traffic
    self.radius_accountings.sum('AcctInputOctets + AcctOutputOctets')
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end

  def radius_name
    username
  end

  def radius_groups_ids
    self.radius_groups.map{|group| group.id}
  end

  def radius_groups_ids=(ids)
    self.radius_groups.clear
    self.radius_groups = RadiusGroup.find([ids].flatten)
  end

  def mobile_phone
    if self.verify_with_mobile_phone?
      "#{self.mobile_prefix}#{self.mobile_suffix}"
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def mobile_phone=(value)
    if self.verify_with_mobile_phone?
      self.mobile_prefix = value[0..2]
      self.mobile_suffix = value[3,-1]
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def credit_card_identity_verify!
    if self.verify_with_credit_card?
      self.verified = true
      self.save!
    else
      Rails.logger.error("Verification method is not 'credit_card'!")
    end
  end

  def mobile_phone_identity_verify!
    if self.verify_with_mobile_phone?
      self.verified = true
      self.save!
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def mobile_phone_password_recover!
    if self.verify_with_mobile_phone?
      self.recovered = true
      self.save!
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def mobile_phone_identity_verify_or_password_recover!
    if self.verified?
      Rails.logger.info("Password recover for '#{self.username}' (id: #{self.id})")
      unless self.recovered?
        self.mobile_phone_password_recover!
        return true
      end
    else
      Rails.logger.info("Verifying '#{self.username}' (id: #{self.id})")
      self.mobile_phone_identity_verify!
      # If the user is not verified because she has disabled her account
      # (i.e. verified == false and recovered == false)
      # we have to recover her password.
      # Default value for recovered is nil (!= false)
      if self.recovered == false
        self.mobile_phone_password_recover!
      end
      return true
    end
    false
  end

  def registration_expire_timeout
    if !self.disabled?
      Rails.logger.error("Account not disabled")
      raise "Account not disabled"
    else
      Configuration.get('disabled_account_expire_days').to_i.days
    end
  end

  def registration_expired?
    expire_in = self.registration_expire_timeout
    expire_in != 0 && (self.updated_at + expire_in) <= Time.now
  end

  # Accessors

  def recovered=(value)
    write_attribute(:recovered, value == true)
    self.recovered_at = Time.now()
  end

end
