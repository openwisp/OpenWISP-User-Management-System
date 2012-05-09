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

class AccountCommon <  ActiveRecord::Base
  set_table_name 'users'

  attr_readonly  :username, :verification_method

  # Macros

  VERIFY_BY_MOBILE = "mobile_phone"
  VERIFY_BY_DOCUMENT = "identity_document"
  VERIFY_BY_CREDIT_CARD = "credit_card"

  VERIFICATION_METHODS = [ VERIFY_BY_DOCUMENT ]
  SELFVERIFICATION_METHODS = Configuration.get("credit_card_enabled") == "true" ? [ VERIFY_BY_MOBILE, VERIFY_BY_CREDIT_CARD ] : [ VERIFY_BY_MOBILE ]

  # Authlogic
  acts_as_authentic do |c|
    c.crypto_provider = NullCryptoProvider # Cleartext password... :(
    c.login_field = :username
    # Validate in the model not in authlogic
    c.validate_login_field = false
    c.validate_email_field = false
    c.validate_password_field = false
    c.session_class = AccountSession
  end

  # Fleximage (identity document)
  acts_as_fleximage do
    require_image false
    invalid_image_message :invalid_image
    missing_image_message :missing_image
    image_storage_format :jpg

    preprocess_image do |image|
      image.resize '800x600'
    end
  end

  # Validations
  validates :username,
      :presence => true,
      :uniqueness => { :allow_blank => true },
      :length => { :in => 4..16, :allow_blank => true },
      :format => { :with => /\A[a-z0-9_\-\.]+\Z/i, :allow_blank => true }

  validates :email,
      :presence => true,
      :uniqueness => { :allow_blank => true },
      :confirmation => { :allow_blank => true },
      :format => {
          :with => /^[A-Z0-9_\.%\+\-']+@(?:[A-Z0-9\-]+\.)+(?:[A-Z]{2,4}|museum|travel)$/i,
          :message => :email_invalid,
          :allow_blank => true
      }

  validates :password, :if => :new_or_password_not_blank?,
      :presence => true,
      :confirmation => { :allow_blank => true },
      :length => { :minimum => 8, :allow_blank => true },
      :format => {
          :with => /\A((\d|[a-z_]|\s)*\d(\d|[a-z_]|\s)*[a-z](\d|[a-z_]|\s)*)|((\d|[a-z_]|\s)*[a-z](\d|[a-z_]|\s)*\d(\d|[a-z_]|\s)*)\Z/i,
          :message => :password_format,
          :allow_blank => true
      }

  validates :mobile_prefix, :if => :verify_with_mobile_phone?,
      :presence => true,
      :confirmation => true,
      :format => { :with => /\A[0-9]+\Z/, :message => :mobile_prefix_format, :allow_blank => true }

  validates :mobile_suffix, :if => :verify_with_mobile_phone?,
      :presence => true,
      :confirmation => true,
      :uniqueness => { :scope => :mobile_prefix, :allow_blank => true },
      :format => { :with => /\A[0-9]+\Z/, :message => :mobile_suffix_format, :allow_blank => true }

  validates :given_name,
      :presence => true,
      :format => { :with => /\A(\w|[\s'àèéìòù])+\Z/i, :message => :name_format, :allow_blank => true }

  validates :surname,
      :presence => true,
      :format => { :with => /\A(\w|[\s'àèéìòù])+\Z/i, :message => :name_format, :allow_blank => true }

  validates :state,
      :presence => true,
      :format => { :with => /\A[a-z\s'\.,]+\Z/i, :message => :address_format }

  validates :city,
      :presence => true,
      :format => { :with => /\A(\w|[\s'\.,\-àèéìòù])+\Z/i, :message => :address_format, :allow_blank => true }

  validates :address,
      :presence => true,
      :format => { :with => /\A(\w|[\s'\.,\/\-àèéìòù])+\Z/i, :message => :address_format, :allow_blank => true }

  validates :zip,
      :presence => true,
      :format => { :with => /[a-z0-9]/, :message => :zip_format, :allow_blank => true }

  validates_presence_of :birth_date
  validates_presence_of :eula_acceptance, :message => :eula_must_be_accepted
  validates_presence_of :privacy_acceptance, :message => :privacy_must_be_accepted

  # Custom validations
  validate :identity_document_is_present, :if => :verify_with_document?
  validate :birth_date_present_and_valid
  validate :no_parameter_tampering # For added security


  # Relations
  has_and_belongs_to_many :radius_groups, :join_table => 'radius_groups_users', :foreign_key => 'user_id'
  has_many :radius_accountings, :foreign_key => :UserName, :primary_key => :username

  # This is a virtual class. See User and Account classes
  attr_accessible

  # Methods

  def self.find_by_mobile_phone(mobile_phone)
    where([ "CONCAT(mobile_prefix,mobile_suffix) = ?", mobile_phone ]).first
  end

  # Accessors

  def verify_with_credit_card?
    self.verification_method == VERIFY_BY_CREDIT_CARD
  end

  def verify_with_mobile_phone?
    self.verification_method == VERIFY_BY_MOBILE
  end

  def verify_with_document?
    self.verification_method == VERIFY_BY_DOCUMENT
  end

  def verified=(value)
    # PLEASE NOTE: verified_at should
    # not be reset to nil (see already_verified_once?)
    if value and !already_verified_once?
      self.verified_at = Time.now
    end
    write_attribute(:verified, value)
  end

  def already_verified_once?
    # An account has verified once
    # if verified_at is not nil
    self.verified_at.present?
  end

  def verification_expire_timeout
    if self.verified?
      Rails.logger.error("Account already verified")
      raise "Account already verified"
    else
      if self.verify_with_mobile_phone?
        Configuration.get('mobile_phone_registration_expire').to_i
      elsif self.verify_with_credit_card?
        Configuration.get('credit_card_registration_expire').to_i
      else
        Rails.logger.error("Invalid verification method")
        raise "Invalid verification method"
      end
    end
  end

  def verification_expired?
    self.created_at + self.verification_expire_timeout <= Time.now
  end

  def disabled?
    !read_attribute(:verified) && !read_attribute(:verified_at).blank?
  end

  # "Virtual" accessors

  def email_confirmation=(value)
    write_attribute(:email_confirmation, value)
  end

  def email_confirmation
    read_attribute(:email_confirmation) ? read_attribute(:email_confirmation) : self.email
  end

  def password_reset_instructions!
    reset_perishable_token!
    Notifier.password_reset_instructions(self).deliver
  end

  def mobile_prefix_confirmation=(value)
    write_attribute(:mobile_prefix_confirmation, value)
  end

  def mobile_prefix_confirmation
    read_attribute(:mobile_prefix_confirmation) ? read_attribute(:mobile_prefix_confirmation) : self.mobile_prefix
  end

  def mobile_suffix_confirmation=(value)
    write_attribute(:mobile_suffix_confirmation, value)
  end

  def mobile_suffix_confirmation
    read_attribute(:mobile_suffix_confirmation) ? read_attribute(:mobile_suffix_confirmation) : self.mobile_suffix
  end

  def last_sessions(count=10)
    radius_accountings.all(:order => "AcctStartTime DESC", :limit => count)
  end

  def session_times_from(date)
    (date.to_date..Date.today).map do |that_day|
      sessions = radius_accountings.all(:conditions => "DATE(AcctStartTime) = '#{that_day.to_s}'")

      duration = sessions.inject(0) do |sum, session|
        if session.AcctStopTime
          single_session = session.acct_stop_time - session.acct_start_time
        else
          single_session = Time.now - session.acct_start_time
        end

        sum + single_session
      end

      [that_day.to_datetime.to_i * 1000, duration]
    end
  end

  def traffic_in_sessions_from(date)
    (date.to_date..Date.today).map do |that_day|
      sessions = radius_accountings.all(:conditions => "DATE(AcctStartTime) = '#{that_day.to_s}'")

      bytes = sessions.inject(0) do |sum, session|
        sum + session.AcctInputOctets
      end

      [that_day.to_datetime.to_i * 1000, bytes]
    end
  end

  def traffic_out_sessions_from(date)
    (date.to_date..Date.today).map do |that_day|
      sessions = radius_accountings.all(:conditions => "DATE(AcctStartTime) = '#{that_day.to_s}'")

      bytes = sessions.inject(0) do |sum, session|
        sum + session.AcctOutputOctets
      end

      [that_day.to_datetime.to_i * 1000, bytes]
    end
  end

  def traffic_sessions_from(date)
    [traffic_out_sessions_from(date), traffic_in_sessions_from(date)]
  end

  private

  def new_or_password_not_blank?
    self.new_record? || !self.password.blank?
  end

  # Custom validation methods

  def identity_document_is_present
    # Overrides default image presence verification performed by Imegeflex
    errors.add(:image_file, self.class.missing_image_message) unless self.has_image?
  end

  def birth_date_present_and_valid
    errors.add(:birth_date, :invalid) unless self.birth_date.nil? || self.birth_date > Date.civil(1920,1,1)
  end

  def no_parameter_tampering
    @countries = Country.all
    unless @countries.map { |p| p.printable_name }.include?(self.state)
      errors.add(:base, "Parameters tampering, uh? Nice try but it's going to be reported...")
      Rails.logger.error("'state' attribute tampering")
    end

    if verify_with_mobile_phone?
      @prefixes  = MobilePrefix.all
      unless @prefixes.map { |p| p.prefix }.include?(self.mobile_prefix.to_i) or self.mobile_prefix.blank? or self.mobile_prefix.nil?
        errors.add(:base, "Parameters tampering, uh? Nice try but it's going to be reported...")
        Rails.logger.error("'mobile_prefix' attribute tampering")
      end
    end
  end
end
