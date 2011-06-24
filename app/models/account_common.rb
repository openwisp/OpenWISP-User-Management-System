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
    c.merge_validates_length_of_password_field_options( { :minimum => 8 } )
    c.merge_validates_format_of_email_field_options(:message => :email_invalid)
    c.validates_length_of_login_field_options = { :in => 4..16 }
    c.validates_format_of_login_field_options = { :with => /\A[a-z0-9_\-\.]+\Z/i }
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
  # # Allowing nil to avoid duplicate error notification (password field is already validated by Authlogic)
  validates_format_of :password, :with => /\A((\d|[a-z_]|\s)*\d(\d|[a-z_]|\s)*[a-z](\d|[a-z_]|\s)*)|((\d|[a-z_]|\s)*[a-z](\d|[a-z_]|\s)*\d(\d|[a-z_]|\s)*)\Z/i, :message => :password_format, :allow_nil => true
  validates_presence_of :eula_acceptance, :message => :eula_must_be_accepted
  validates_presence_of :privacy_acceptance, :message => :privacy_must_be_accepted
  validates_presence_of :mobile_prefix, :if => Proc.new { |user| user.verify_with_mobile_phone? }
  validates_presence_of :mobile_suffix, :if => Proc.new { |user| user.verify_with_mobile_phone? }
  validates_uniqueness_of :mobile_suffix, :scope => :mobile_prefix, :allow_nil => true,
                          :if => Proc.new { |user| user.verify_with_mobile_phone? }
  validates_format_of :mobile_prefix, :allow_nil => true, :with => /\A[0-9]+\Z/, :message => :mobile_prefix_format,
                      :if => Proc.new { |user| user.verify_with_mobile_phone? }
  validates_format_of :mobile_suffix, :allow_nil => true, :with => /\A[0-9]+\Z/, :message => :mobile_suffix_format,
                      :if => Proc.new { |user| user.verify_with_mobile_phone? }
  validates_presence_of :birth_date
  validates_presence_of :given_name
  validates_format_of :given_name, :with => /\A(\w|[\s'])+\Z/i, :message => :name_format
  validates_presence_of :surname
  validates_format_of :surname, :with => /\A(\w|[\s'])+\Z/i, :message => :name_format
  validates_presence_of :state
  validates_format_of :state, :with => /\A[a-z\s'\.,]+\Z/i, :message => :addres_format
  validates_presence_of :city
  validates_format_of :city, :with => /\A(\w|[\s'\.,\-])+\Z/i, :message => :address_format
  validates_presence_of :address
  validates_format_of :address, :with => /\A(\w|[\s'\.,\/\-])+\Z/i, :message => :address_format
  validates_presence_of :zip
  validates_format_of :zip, :with => /[a-z0-9]/, :message => :zip_format


  has_and_belongs_to_many :radius_groups, :join_table => 'radius_groups_users', :foreign_key => 'user_id'
  has_many :radius_accountings, :foreign_key => :UserName, :primary_key => :username

  # Methods

  def validate
    # Check e-mail confirmation
    if self.email_changed? or !read_attribute(:email_confirmation).nil?
      if self.email != read_attribute(:email_confirmation)
        errors.add(:email, :confirmation)
      end
    end
    # Check mobile_phone confirmation
    if self.verify_with_mobile_phone?
      if self.mobile_prefix_changed? or !read_attribute(:mobile_prefix_confirmation).nil?
        if self.mobile_prefix != read_attribute(:mobile_prefix_confirmation)
          errors.add(:mobile_prefix, :confirmation)
        end
      end
      if self.mobile_suffix_changed? or !read_attribute(:mobile_suffix_confirmation).nil?
        if self.mobile_suffix != read_attribute(:mobile_suffix_confirmation)
          errors.add(:mobile_suffix, :confirmation)
        end
      end
    end
    # Check identity document
    if self.verify_with_document?
      # Overrides default image presence verification performed by Imegeflex
      if !self.has_image?
        errors.add(:image_file, self.class.missing_image_message)
      end
    end

    # Check "enum"-ered fields

    @countries = Country.find :all, :conditions => "disabled = 'f'"
    unless @countries.map { |p| p.printable_name }.include?(self.state)
      errors.add_to_base("Parameter's tampering, uh? Nice try but it's going to be reported...")
      Rails.logger.error("'state' attribute tampering")
    end
    if self.verify_with_mobile_phone?
      @prefixes  = MobilePrefix.find :all, :conditions => "disabled = 'f'"
      unless @prefixes.map { |p| p.prefix }.include?(self.mobile_prefix.to_i) or self.mobile_prefix.blank? or self.mobile_prefix.nil?
        errors.add_to_base("Parameter's tampering, uh? Nice try but it's going to be reported")
        Rails.logger.error("'mobile_prefix' attribute tampering")
      end
    end

    # Check birthdate

    unless self.birth_date.nil? || self.birth_date > Date.civil(1920,1,1)
      errors.add(:birth_date, :invalid)
    end

  end


  def self.find_by_mobile_phone(mobile_phone)
    find(:first, :conditions => [ "CONCAT(mobile_prefix,mobile_suffix) = ?", mobile_phone ])
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
end
