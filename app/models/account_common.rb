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

class AccountCommon < ActiveRecord::Base
  set_table_name 'users'

  attr_readonly :username, :verification_method

  # Macros

  VERIFY_BY_MOBILE = "mobile_phone"
  VERIFY_BY_DOCUMENT = "identity_document"
  VERIFY_BY_GESTPAY = "gestpay_credit_card"
  VERIFY_BY_NOTHING = "no_identity_verification"
  VERIFY_BY_MACADDRESS = "mac_address"
  VERIFY_BY_SOCIAL = "social_network"

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
            :uniqueness => {:allow_blank => true},
            :length => {:in => 4..64, :allow_blank => true},
            :format => {:with => /\A[a-z0-9_\-\.]+\Z/i, :allow_blank => true}

  validates :email,
            :presence => true,
            :uniqueness => {:allow_blank => true},
            :confirmation => {:allow_blank => true},
            :format => {
                :with => /^[A-Z0-9_\.%\+\-']+@(?:[A-Z0-9\-]+\.)+(?:[A-Z]{2,4}|museum|travel)$/i,
                :message => :email_invalid,
                :allow_blank => true
            }

  validates :password, :if => :password_required?,
            :presence => true,
            :confirmation => {:allow_blank => true},
            :length => {:minimum => 8, :allow_blank => true},
            :format => {
                :with => /\A((\d|[a-z_]|\s)*\d(\d|[a-z_]|\s)*[a-z](\d|[a-z_]|\s)*)|((\d|[a-z_]|\s)*[a-z](\d|[a-z_]|\s)*\d(\d|[a-z_]|\s)*)\Z/i,
                :message => :password_format,
                :allow_blank => true
            }

  validates :mobile_prefix, :if => :validate_mobile_phone?,
            :presence => true,
            :confirmation => true,
            :format => {:with => /\A[0-9]+\Z/, :message => :mobile_prefix_format, :allow_blank => true}

  validates :mobile_suffix, :if => :validate_mobile_phone?,
            :presence => true,
            :confirmation => true,
            :uniqueness => {:scope => :mobile_prefix, :allow_blank => true},
            :format => {:with => /\A[0-9]+\Z/, :message => :mobile_suffix_format, :allow_blank => true}

  validates :given_name,
            :presence => true,
            :format => {:with => /\A(\w|[\s'àèéìòù])+\Z/i, :message => :name_format, :allow_blank => true}

  validates :surname,
            :presence => true,
            :format => {:with => /\A(\w|[\s'àèéìòù])+\Z/i, :message => :name_format, :allow_blank => true}

  if CONFIG['state']
    validates :state,
              :presence => true,
              :format => {:with => /\A[a-z\s'\.,]+\Z/i, :message => :address_format}
  end

  if CONFIG['city']
    validates :city,
              :presence => true,
              :format => {:with => /\A(\w|[\s'\.,\-àèéìòù])+\Z/i, :message => :address_format, :allow_blank => true}
  end

  if CONFIG['address']
    validates :address,
              :presence => true,
              :format => {:with => /\A(\w|[\s'\.,\/\-àèéìòù])+\Z/i, :message => :address_format, :allow_blank => true}
  end

  if CONFIG['zip']
    validates :zip,
              :presence => true,
              :format => {:with => /[a-z0-9]/, :message => :zip_format, :allow_blank => true}
  end

  if CONFIG['birth_date']
    validates_presence_of :birth_date
    validate :birth_date_present_and_valid
  end

  validates_presence_of :eula_acceptance, :message => :eula_must_be_accepted
  validates_presence_of :privacy_acceptance, :message => :privacy_must_be_accepted

  # Custom validations
  validate :identity_document_is_present, :if => :verify_with_document?
  validate :no_parameter_tampering # For added security

  # Relations
  has_and_belongs_to_many :radius_groups, :join_table => 'radius_groups_users', :foreign_key => 'user_id'
  has_many :radius_accountings, :foreign_key => :UserName, :primary_key => :username
  has_many :social_auths, :dependent => :destroy, :foreign_key => 'user_id'
  # This is a virtual class. See User and Account classes
  attr_accessible

  # Class Methods

  def self.find_by_mobile_phone(mobile_phone)
    where(["CONCAT(mobile_prefix,mobile_suffix) = ?", mobile_phone]).first
  end

  def self.verification_methods
    operator = defined?(OperatorSession.find.operator) ? OperatorSession.find.operator : false
    is_console = !!defined?(Rails::Console)
    methods = []

    if is_console or operator
      methods.push VERIFY_BY_NOTHING  if is_console or operator.has_role?('registrant_by_nothing')
      methods.push VERIFY_BY_DOCUMENT if is_console or operator.has_role?('registrant_by_id_card')
    end
    methods.push VERIFY_BY_MACADDRESS if CONFIG['mac_address_authentication']

    methods
  end

  def self.self_verification_methods
    methods = [VERIFY_BY_MOBILE]

    methods.push(VERIFY_BY_GESTPAY) if CONFIG['gestpay_enabled']
    methods.push(VERIFY_BY_SOCIAL) if CONFIG['social_login_enabled']

    if !!defined?(Rails::Console)
      methods.push VERIFY_BY_NOTHING
      methods.push VERIFY_BY_DOCUMENT
    end

    methods
  end

  def self.search_verification_methods
    methods = [VERIFY_BY_MOBILE]
    methods.push(VERIFY_BY_GESTPAY) if CONFIG['gestpay_enabled']
    methods.push(VERIFY_BY_SOCIAL) if CONFIG['social_login_enabled']
    
    methods += self.verification_methods
    methods
  end

  def self.social_login_ask_mobile_phone
    return Configuration.get('social_login_ask_mobile_phone', 'unverified')
  end

  # Instance Methods

  def to_xml(options={})
    options.merge!(:except => [:single_access_token,
                               :crypted_password,
                               :password_salt,
                               :persistence_token,
                               :perishable_token])
    super(options)
  end

  # Accessors

  def verify_with_gestpay?
    self.verification_method == VERIFY_BY_GESTPAY
  end

  def verify_with_mobile_phone?
    self.verification_method == VERIFY_BY_MOBILE
  end

  def verify_with_document?
    self.verification_method == VERIFY_BY_DOCUMENT
  end

  def verify_with_social?
    self.verification_method == VERIFY_BY_SOCIAL
  end

  def verify_with_social_and_mobile?
    # allow creation of new users with empty mobile
    if self.verify_with_social? and Account.social_login_ask_mobile_phone != 'never' and self.id and !self.verified?
      return true
    else
      return false
    end
  end

  def validate_mobile_phone?
    self.verify_with_mobile_phone? or self.verify_with_social_and_mobile?
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
      elsif self.verify_with_gestpay?
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

  def set_credit_card_info(data)
    values = {}
    if data.has_key?(:shop_transaction_id) && !data[:shop_transaction_id].nil?
      values[:shop_transaction] = data[:shop_transaction_id]
    end
    if data.has_key?(:datetime) && !data[:datetime].nil?
      values[:datetime] = data[:datetime]
    end
    if data.has_key?(:bank_transaction_id) && !data[:bank_transaction_id].nil?
      values[:bank_transaction] = data[:bank_transaction_id]
    end
    if data.has_key?(:authorization_code) && !data[:authorization_code].nil?
      values[:authorization_code] = data[:authorization_code]
    end
    if data.has_key?(:vb_v) && !data[:vb_v].nil?
      values[:transaction_key] = data[:transaction_key]
      values[:VbVRisp] = data[:vb_v][:vb_v_risp]
    end
    self.credit_card_info = values.to_json
  end

  def generate_invoice!
    verification_method = Configuration.get('gestpay_webservice_method')
    invoicing_enabled = Configuration.get('gestpay_invoicing_enabled', 'true')
    # do not generate invoice for verification operations
    # or if invoicing is explicitly disabled
    if verification_method == 'verification' or invoicing_enabled != 'true'
      return false
    end

    invoice = Invoice.create_for_user(User.find(self.id))

    # generate PDF with an asynchronous job with sidekiq
    # unfortunately sidekiq needs ruby 1.9.3
    # send PDF via email to both user and admin
    filename = invoice.generate_pdf()

    # send invoice to admin
    Notifier.send_invoice_to_admin(filename).deliver

    return filename
  end

  def credit_card_identity_verify!
    if verify_with_gestpay?
      self.verified = true
      self.save!

      filename = self.generate_invoice!
      # pass filename to new_account_notification
      self.new_account_notification!(filename)

      self.captive_portal_login!
    else
      Rails.logger.error("Verification method is not 'gestpay_credit_card'!")
    end
  end

  def mobile_phone_identity_verify!
    if self.verify_with_mobile_phone?
      self.verified = true
      self.save!
      self.new_account_notification!
      self.captive_portal_login!
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def password_reset_instructions!
    reset_perishable_token!
    Notifier.password_reset_instructions(self).deliver
  end

  def new_account_notification!(filename=false)
    if CONFIG['send_email_notification_to_users']
      Notifier.new_account_notification(self, filename).deliver
    end
  end

  def captive_portal_login(ip_address=false, timeout=false, config_check=true)
    # to use indipendently from configuration supply :config_check => false
    if not CONFIG['automatic_captive_portal_login'] and config_check
      return false
    end

    # determine ip address
    ip_address = ip_address ? ip_address : self.current_login_ip
    # automatically log in an user in the captive portal to allow the user to surf
    cp_base_url = Configuration.get('captive_portal_baseurl', false)

    if cp_base_url
      params = {
        :username => self.username,
        :password => self.crypted_password,
        :ip => ip_address
      }
      # specify session timeout if necessary to achieve a temporary login
      if timeout
        params[:timeout] = Configuration.get('gestpay_vbv_session', '300').to_i
      end

      uri = URI::parse "#{cp_base_url}/api/v1/account/login"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)
      http.request(request)
    else
      raise 'key captive_portal_baseurl not present in the database'
    end
  end

  alias captive_portal_login! captive_portal_login

  def captive_portal_logout(ip_address=false)
    # determine ip address
    ip_address = ip_address ? ip_address : self.last_login_ip
    cp_base_url = Configuration.get('captive_portal_baseurl', false)
    if cp_base_url
      params = {
        :username => self.username,
        :ip => ip_address
      }
      uri = URI::parse "#{cp_base_url}/api/v1/account/logout"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)
      http.request(request)
    else
      raise 'key captive_portal_baseurl not present in the database'
    end
  end

  # determine if a login attempt is ok for verified by visa users
  def captive_portal_login_ok_for_vbv?(login_response)
    # successfully logged in
    if login_response.code == "200"
      return true
    end
    # not logged in most probably because the user is registering from her own internet connection and not from one of our APs
    if login_response.code == "403" and (login_response.body.include?('non associato') or login_response.body.include?('not associated'))
      return true
    end
    # something is wrong
    return false
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

  def password_required?
    self.new_record? || !self.password.blank?
  end

  # Custom validation methods

  def identity_document_is_present
    # Overrides default image presence verification performed by Imegeflex
    errors.add(:image_file, self.class.missing_image_message) unless self.has_image?
  end

  def birth_date_present_and_valid
    errors.add(:birth_date, :invalid) unless self.birth_date.nil? || self.birth_date > Date.civil(1920, 1, 1)
  end

  def no_parameter_tampering
    @countries = Country.all
    unless CONFIG['state'] == false || @countries.map { |p| p.printable_name }.include?(self.state)
      errors.add(:base, "Parameters tampering, uh? Nice try but it's going to be reported...")
      Rails.logger.error("'state' attribute tampering")
    end

    if verify_with_mobile_phone?
      @prefixes = MobilePrefix.all
      unless @prefixes.map { |p| p.prefix }.include?(self.mobile_prefix.to_i) or self.mobile_prefix.blank? or self.mobile_prefix.nil?
        errors.add(:base, "Parameters tampering, uh? Nice try but it's going to be reported...")
        Rails.logger.error("'mobile_prefix' attribute tampering")
      end
    end
  end
end
