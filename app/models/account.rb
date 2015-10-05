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

class Account < AccountCommon

  acts_as_easy_captcha

  # Authlogic
  acts_as_authentic do |c|
    c.maintain_sessions = true
  end

  # After save
  #after_save :prepare_gestpay_payment

  # If the configuration key use_mobile_phone_as_username is set to true, the username is automatically set
  before_validation :set_username_if_required, :on => :create
  before_validation :clean_fields

  # Validations
  validates_inclusion_of :verification_method, :in => User.self_verification_methods, :if => Proc.new{|account| account.new_record? }
  validate :valid_captcha?, :message => 'dummy', :on => :create, :if => Proc.new{|account| account.validate_captcha? }
  validates :username, :uniqueness => { :case_sensitive => false }

  # Security and cleanup
  attr_readonly  :given_name, :surname, :birth_date
  # :verified should never be set with mass-assignment!
  attr_accessible :username, :given_name, :surname, :birth_date, :state, :city, :address, :zip,
                  :email, :email_confirmation, :password, :password_confirmation,
                  :mobile_prefix, :mobile_prefix_confirmation, :mobile_suffix,
                  :mobile_suffix_confirmation, :verification_method,
                  :eula_acceptance, :privacy_acceptance, :captcha

  def validate_captcha?
    @validate_captcha == true
  end

  def save_with_captcha
    @validate_captcha = true
    save
  end

  def duplicate?
    if not self.errors
      return false
    else
      taken = I18n.t("activerecord.errors.messages.taken")
      # if username, mobile_suffix or email already taken return true, otherwise return false
      [:username, :mobile_suffix, :email].any? do |key|
        self.errors.key?(key) and self.errors[key.to_sym].include?(taken)
      end
    end
  end

  # Class methods

  def self.total_traffic
    total_megabytes = 0
    Account.all.each do |account|
      account.radius_accountings.each do |acct|
        total_megabytes += acct.traffic_in_mega.to_f
        total_megabytes += acct.traffic_out_mega.to_f
      end
    end

    sprintf "%.2f", total_megabytes
  end

  def self.total_in_traffic
    total_in_megabytes = 0
    Account.all.each do |account|
      account.radius_accountings.each do |acct|
        total_in_megabytes += acct.traffic_in_mega.to_f
      end
    end

    sprintf "%.2f", total_in_megabytes
  end

  def self.total_out_traffic
    total_out_megabytes = 0
    Account.all.each do |account|
      account.radius_accountings.each do |acct|
        total_out_megabytes += acct.traffic_out_mega.to_f
      end
    end

    sprintf "%.2f", total_out_megabytes
  end

  def self.find_or_create_from_oauth(auth_hash)
    authorization = SocialAuth.find_by_provider_and_uid(auth_hash["provider"], auth_hash["uid"])

    if authorization
      account = Account.find(authorization.user_id)
      # this block is entered when the user disabled her account
      # in this case we'll re-enable it, because doing the social login again
      # is equivalent to verifying the phone number again
      if !account.verified and account.mobile_suffix and account.mobile_prefix
        account.verified = true
        account.save
      end
      return account
    else
      # try to grab birthday, city and state
      if auth_hash["extra"] and auth_hash["extra"]["raw_info"]
        extra = auth_hash["extra"]["raw_info"]
        if extra["birthday"]
          birth_date = extra["birthday"].gsub("/", "-")
        end
        if extra["location"] and extra["location"]["name"]
          city, state = extra["location"]["name"].split(", ")
        end
      end

      first_name = auth_hash["info"]["first_name"]
      last_name = auth_hash["info"]["last_name"]
      # password is needed for captive portal login
      password = SecureRandom.hex
      # default values for additional fields
      default_birth_date = CONFIG['birth_date'] ? '01-01-1970' : ''
      default_address = CONFIG['address'] ? 'null' : ''
      default_city = CONFIG['city'] ? 'null' : ''
      default_state = CONFIG['state'] ? 'null' : ''
      default_zip = CONFIG['zip'] ? 'null' : ''

      account = Account.new(
        :given_name => first_name,
        :surname => last_name,
        :email => auth_hash["info"]["email"],
        :username => "#{first_name}.#{last_name}",
        :password => password,
        :password_confirmation => password,
        :verification_method => 'social_network',
        :birth_date => birth_date || default_birth_date,
        :address => default_address,
        :city => city || default_city,
        :state => state || default_state,
        :zip => default_zip,
        :eula_acceptance => true,
        :privacy_acceptance => true,
        :active => true
      )
      # username lowercase withouth dashes
      account.username = account.username.downcase.gsub(' ', '-')
      # find available username
      original_username = account.username
      counter = 1
      while Account.where(:username => account.username).count > 0
        counter += 1
        account.username = "#{original_username}#{counter}"
      end
      account.radius_groups << RadiusGroup.find_by_name!(Configuration.get('default_radius_group'))

      ask = Account.social_login_ask_mobile_phone
      if ask == 'never' or (ask == 'unverified' and auth_hash["info"]["verified"] == true)
        account.verified = true
      end

      if account.save
        auth = SocialAuth.new(
          :user_id => account.id,
          :provider => auth_hash["provider"],
          :uid => auth_hash["uid"]
        )
        auth.save!
        account.new_account_notification!
      end

      return account
    end
  end

  # Utilities

  def can_signup_via?(verification_method)
    User.self_verification_methods.include? verification_method
  end

  def expire_time
    (self.verification_expire_timeout - (Time.now - self.created_at).to_i + 60) / 60
  end

  def expire_seconds
    (self.verification_expire_timeout - (Time.now - self.created_at).to_i)
  end

  def verification_time_remaining
    if not self.verified? and self.expire_seconds > 0
      Time.at(self.expire_seconds).gmtime.strftime('%M:%S')
    else
      return 0
    end
  end

  def ask_for_mobile_phone_password_recovery!
    if self.verify_with_mobile_phone?
      self.reset_single_access_token
      self.reset_perishable_token
      self.recovered = false
      self.save!
      Rails.logger.warn("Account recover asked for '#{self.username}'")
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def ask_for_mobile_phone_identity_verification!
    if self.verify_with_mobile_phone?
      self.verified = false
      self.save!
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def save_from_mobile_phone_password_recovery
    self.reset_single_access_token
    self.reset_perishable_token
    self.save_without_session_maintenance
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
      self.mobile_suffix = value[3,-1]
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def gestpay_s2s_verify_credit_card(request, cc, amount, currency)
    # build credit card number
    number = cc['number1'] + cc['number2'] + cc['number3'] + cc['number4']
    # verify validity of credit card before sending it to the gateway
    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :number     => number,
      :month      => cc['expiration_month'],
      :year       => '20'+cc['expiration_year'],
      :first_name => self.given_name,
      :last_name  => self.surname,
      :verification_value  => cc['cvv']
    )

    transaction = CreditCardTransaction.new(
      :user_id => self.id,
      :ip_address => request.remote_ip,
      :amount => amount
    )

    transaction_valid = transaction.valid?

    # if credit card looks valid proceed to bank gateway
    if credit_card.valid? and transaction_valid
      webservice_url = Configuration.get('gestpay_webservice_url')
      time = DateTime.now
      shop_transaction_id = Digest::MD5.hexdigest("#{number}#{time}")
      # prepare SOAP params
      params = {
        :shopLogin => Configuration.get('gestpay_shoplogin'),
        :uicCode => currency,
        :amount => amount,
        :shopTransactionId => shop_transaction_id,
        :cardNumber => number,
        :expiryMonth => cc['expiration_month'].length > 1 ? cc['expiration_month'] : '0' + cc['expiration_month'],
        :expiryYear => cc['expiration_year'],
        :cvv => cc['cvv'],
        :buyerName => '%s %s' % [self.given_name, self.surname],
        :buyerEmail => self.email,
        :languageId => I18n.locale == :it ? '1' : '2',
        :customInfo => "USERID=%s*P1*SERVER=%s" % [self.id.to_s, Configuration.get("notifier_base_url")]
      }
      # init SOAP client
      client = Savon.client(webservice_url)

      if Configuration.get('gestpay_webservice_method') == 'verification'
        method = :call_verifycard_s2_s
        params[:expMonth] = params[:expiryMonth]
        params[:expYear] = params[:expiryYear]
        params.delete(:amount)
        params.delete(:expiryMonth)
        params.delete(:expiryYear)
      else
        method = :call_pagam_s2_s
      end

      # execute a SOAP request to call the "callPagamS2S" action
      response = client.request(method) do
        soap.body = params
      end

      # convert response to hash
      begin
        response = response.to_hash[:call_pagam_s2_s_response][:call_pagam_s2_s_result][:gest_pay_s2_s]
      rescue NoMethodError
        response = response.to_hash[:call_verifycard_s2_s_response][:call_verifycard_s2_s_result][:gest_pay_s2_s]
      end

      response[:datetime] = time
      response[:shop_transaction_id] = shop_transaction_id
      # if verification and payment succeded
      if response[:transaction_result] == 'OK':
        # save bank response (shop_transaction, authorization_code) and verify user
        self.set_credit_card_info(response)
        self.credit_card_identity_verify!
      # verified by visa case
      elsif response[:error_code] == '8006'
        # save shop_transaction_id, transaction_key and vbv_risp in DB
        self.set_credit_card_info(response)
        # prolong account validity so it won't expire while the user is verifying
        self.created_at = time
        # temporarily set the user as verified in order to be able to log her in just for the time necessary to complete the payment
        self.verified = true
        self.save!
        # temporarily login user
        login_response = self.captive_portal_login(request.remote_ip, timeout=true, config_check=false)
        # unverify user
        self.verified = false
        self.save!
        # ensure user is logged in otherwise log error and return failure
        if self.captive_portal_login_ok_for_vbv?(login_response)
          # add some keys to response hash
          response[:a] = params[:shopLogin]
          response[:b] = response[:vb_v][:vb_v_risp]
          response[:url] = Configuration.get('gestpay_vbv_url')
        # one of the 403 cases can happen when a user is not registering from an access point but from another internet connection
        else
          Rails.logger.error('captive portal login failed for verified_by_visa credit card user with error %s: %s' % [login_response.code, login_response.body])
          response[:error_description] = I18n.t(:VBV_system_error)
          response[:error_code] = false
        end
      else
        self.set_credit_card_info(response)
      end

      begin
        transaction.credit_card_info = self.credit_card_info
        transaction.save!
      rescue => e
        ExceptionNotifier::Notifier.background_exception_notification(e).deliver
      end

      # explicit return just for clarity
      return response
    end

    # translate active merchant errors and display them nicely
    error_description = ''
    i = 0
    credit_card.errors.each do |key, value|
      if value.empty?
        next
      end
      br = i > 0 ? '<br />' : ''
      error_description = error_description + br + I18n.t("active_merchant_#{key}")
      i += 1
    end

    if error_description == '' and !transaction_valid
      error_description = transaction.errors[:id][0]
    end

    # emulate gestpay response
    return { :transaction_result => 'KO', :error_description => error_description, :error_code => false }
  end

  def gestpay_s2s_verified_by_visa(pares, ip_address)
    webservice_url = Configuration.get('gestpay_webservice_url')
    amount = Configuration.get('credit_card_verification_cost', '1')
    currency = Configuration.get('gestpay_currency')
    # retrieve data from DB
    credit_card_info = JSON::load(self.credit_card_info)
    # prepare SOAP params
    params = {
      :shopLogin => Configuration.get('gestpay_shoplogin'),
      :uicCode => currency,
      :amount => amount,
      :shopTransactionId => credit_card_info['shop_transaction'],
      :transKey => credit_card_info['transaction_key'],
      "PARes" => pares
    }
    # init SOAP client
    client = Savon.client(webservice_url)
    # execute a SOAP request to call the "callPagamS2S" action
    response = client.request(:call_pagam_s2_s) do
      soap.body = params
    end
    # convert response to hash
    response = response.to_hash[:call_pagam_s2_s_response][:call_pagam_s2_s_result][:gest_pay_s2_s]

    if response[:transaction_result] == 'OK'
      response[:datetime] = credit_card_info['datetime']
      response[:transaction_key] = credit_card_info['transaction_key']
      response[:VbVRisp] = credit_card_info['VbVRisp']
      self.set_credit_card_info(response)
      # log out user from captive portal because he's using a temporary login
      self.captive_portal_logout(ip_address)
      # this method will login the user again if the default configuration has not been changed (config.yml)
      self.credit_card_identity_verify!
    end
    return response
  end

  private

  def set_username_if_required
    if Configuration.get('use_mobile_phone_as_username') == "true"
      if verify_with_mobile_phone?
        self.username = mobile_phone
      end
    end
  end

  def clean_fields
    # regular cases
    if not self.validate_mobile_phone?
      self.mobile_prefix = nil
      self.mobile_suffix = nil
    elsif not self.verify_with_document?
      self.image_file_data = nil
    end
  end

  # Validations
  def valid_captcha?
    if(Configuration.get('captcha_enabled', 'true') == 'true')
      # Redefines method from easy_captcha to
      # use custom error message
      errors.add(:captcha, :invalid_captcha) if @captcha.blank? or @captcha_verification.blank? or @captcha.to_s.upcase != @captcha_verification.to_s.upcase
    end
  end
end
