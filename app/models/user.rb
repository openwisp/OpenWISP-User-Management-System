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

  self.before_validation { |record|
    # Cleaning up unused fields... just in case..

    if record.verification_method == User::VERIFY_BY_DOCUMENT
      record.mobile_prefix = nil
      record.mobile_suffix = nil
    elsif record.verification_method == User::VERIFY_BY_MOBILE
      record.image_file_data = nil
    end
  }

  # Validations
  # # Allowing nil to avoid duplicate error notification (password field is already validated by Authlogic)
  validates_inclusion_of :verification_method, :in => User::VERIFICATION_METHODS,
    :unless => Proc.new{|user| User::SELFVERIFICATION_METHODS.include? user.verification_method }

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
    top = RadiusAccounting.all(:select => 'Username',
                               :group => :UserName,
                               :order => 'sum(AcctInputOctets + AcctOutputOctets) DESC',
                               :limit => num)
    ret = []
    top.each do |t|
        user = User.find_by_username(t.Username)
        ret.push(user) unless user.nil?
    end

    ret
  end

  def self.find_all_by_user_phone_or_mail(query)
    find(:all, :conditions => [ "username = ? OR CONCAT(mobile_prefix,mobile_suffix) = ? OR email = ?" ] + [query]*3)
  end

  def self.registered_each_day_from(date)
    (date.to_date..Date.today).map do |that_day|
      [that_day.to_datetime.to_i * 1000, registered_on(that_day)]
    end
  end

  def self.registered_on(date)
    count :conditions => "Date(verified_at) <= '#{date.to_s}'"
  end

  def self.registered_yesterday
    find(:all, :conditions => { :created_at => 1.day.ago..DateTime.now })
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
    if self.verification_method == User::VERIFY_BY_MOBILE
      "#{self.mobile_prefix}#{self.mobile_suffix}"
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def mobile_phone=(value)
    if self.verification_method == User::VERIFY_BY_MOBILE
      self.mobile_prefix = value[0..2]
      self.mobile_suffix = value[3,-1]
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def credit_card_identity_verify!
    if self.verification_method == User::VERIFY_BY_CREDIT_CARD
      self.verified = true
      self.save!
    else
      Rails.logger.error("Verification method is not 'credit_card'!")
    end
  end

  def mobile_phone_identity_verify!
    if self.verification_method == User::VERIFY_BY_MOBILE
      self.verified = true
      self.save!
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def mobile_phone_password_recover!
    if self.verification_method == User::VERIFY_BY_MOBILE
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
      Rails.logger.info("Verifing '#{self.username}' (id: #{self.id})")
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
    return false
  end

  # Accessors

  def recovered=(value)
    write_attribute(:recovered, value == true)
    self.recovered_at = Time.now()
  end

end
