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

class User < AccountCommon

  # Authlogic
  acts_as_authentic do |c|
    c.maintain_sessions = false
  end

  self.before_validation do |record|
    # Cleaning up unused fields... just in case..
    if record.verify_with_document?
      record.mobile_prefix = nil
      record.mobile_suffix = nil
    elsif record.verify_with_mobile_phone?
      record.image_file_data = nil
    end
  end

  # Validations
  validate :verification_method_inclusion

  has_many :radius_checks, :as => :radius_entity, :dependent => :destroy
  has_many :radius_replies, :as => :radius_entity, :dependent => :destroy
  has_one :invoice

  attr_accessible :given_name, :surname, :birth_date, :state, :city, :address, :zip,
                  :email, :email_confirmation, :password, :password_confirmation,
                  :mobile_prefix, :mobile_suffix, :verified, :active, :verification_method,
                  :notes, :eula_acceptance, :privacy_acceptance,
                  :username, :image_file_temp, :image_file, :image_file_data, :radius_group_ids

  # Custom validations

  def verification_method_inclusion
    valid_verification_methods = User.verification_methods + (self.new_record? ? [] : User.self_verification_methods)

    errors.add(:verification_method, I18n.t(:inclusion, :scope => [:activerecord, :errors, :messages])) unless valid_verification_methods.include?(verification_method)
  end

  # Class methods

  def self.last_registered(num = 5)
    User.order("created_at DESC").limit(num)
  end

  def self.find_by_id_or_username!(id)
    User.find id
  rescue ActiveRecord::RecordNotFound
    User.find_by_username! id
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
    where(["username = ? OR CONCAT(mobile_prefix,mobile_suffix) = ? OR email = ?"] + [query]*3)
  end

  def self.registered_each_day(from, to, verification_method=nil)
    (from..to).map { |that_day|
      on_that_day = User.registered_on(that_day, verification_method)
      [that_day.to_datetime.to_i * 1000, on_that_day] if on_that_day > 0
    }.compact
  end

  def self.registered_daily(from, to, verification_method=nil)
    (from..to).map { |that_day|
      on_that_day = User.registered_exactly_on(that_day, verification_method)
      [that_day.to_datetime.to_i * 1000, on_that_day] if on_that_day > 0
    }.compact
  end

  def self.registered_on(date, verification_method=nil)
    conditions = ["verified = 1 AND verified_at < ?", date.to_date+1]
    if verification_method
      conditions[0] << " AND verification_method = ?"
      conditions.push(verification_method)
    end

    count :conditions => conditions
  end

  def self.registered_exactly_on(date, verification_method=nil)
    conditions = ["verified = 1 AND verified_at >= ? AND verified_at < ?", date.to_date, date.to_date+1]
    if verification_method
      conditions[0] << " AND verification_method = ?"
      conditions.push(verification_method)
    end

    count :conditions => conditions
  end

  def self.registered_yesterday
    where({:created_at => 1.day.ago..DateTime.now})
  end

  def self.unverified
    where("verified_at is NULL AND NOT verified")
  end

  # unverified users that can be cleaned up by house keeper worker
  def self.unverified_destroyable
    where("verified_at is NULL AND NOT verified AND NOT verification_method = 'gestpay_credit_card'")
  end

  # unverified users that can be deactivated by house keeper worker
  def self.unverified_deactivable
    where("verified_at is NULL AND NOT verified AND active AND verification_method = 'gestpay_credit_card'")
  end

  def self.disabled
    # This method uses verified_at and verified instead
    # of active, to let the user disable (and subsequent remove)
    # itself autonomously
    where("verified_at is NOT NULL AND NOT verified")
  end

  def self.disabled_destroyable
    where("verified_at is NOT NULL AND NOT verified AND NOT verification_method = 'gestpay_credit_card'")
  end

  def self.disabled_deactivable
    where("verified_at is NOT NULL AND NOT verified AND active AND verification_method = 'gestpay_credit_card'")
  end

  # Instance Methods

  def to_xml(options={})
    options.merge!(:include => :radius_groups)
    super(options)
  end

  # Utilities

  def can_signup_via?(verification_method)
    User.verification_methods.include? verification_method
  end

  def total_traffic
    self.radius_accountings.sum('AcctInputOctets + AcctOutputOctets')
  end

  def radius_name
    username
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
      self.mobile_suffix = value[3, -1]
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
      unless self.recovered
        self.mobile_phone_password_recover!
      end
      return true
    end
    false
  end

  def registration_expire_timeout
    if self.disabled?
      Configuration.get('disabled_account_expire_days').to_i.days
    else
      Rails.logger.error("Account not disabled")
      raise "Account not disabled"
    end
  end

  def registration_expired?
    expire_in = self.registration_expire_timeout
    expire_in != 0 && (self.updated_at + expire_in) <= Time.now
  end

  # Accessors

  def recovered=(value)
    write_attribute(:recovered, value)
    self.recovered_at = Time.now()
  end

end
