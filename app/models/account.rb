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

  # Validations
  validates_inclusion_of :verification_method, :in => User.self_verification_methods, :if => Proc.new{|account| account.new_record? }
  validate :valid_captcha?, :message => 'dummy', :on => :create, :if => Proc.new{|account| account.validate_captcha? }

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


  # Utilities

  def can_signup_via?(verification_method)
    User.self_verification_methods.include? verification_method
  end

  def expire_time
    (self.verification_expire_timeout - (Time.now - self.created_at).to_i + 60) / 60
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

  def verify_with_paypal(return_url, notify_url)
    prepared = prepare_paypal_payment(return_url, notify_url)
    prepared[:paypal_base_url]+ '?' + prepared[:values].map { |k,v| "#{k}=#{v}"  }.join("&")
  end

  def encrypted_verify_with_paypal(return_url, notify_url)
    prepared = prepare_paypal_payment(return_url, notify_url)

    prepared[:values].merge!({:cert_id => Configuration.get("ipn_cert_id")})
    prepared[:values].merge!({:secret => Configuration.get("ipn_shared_secret")})

    paypal_cert = File.read("#{Rails.root}/certs/paypal_cert.pem")
    owums_cert = File.read("#{Rails.root}/certs/owums_cert.pem")
    owums_key = File.read("#{Rails.root}/certs/app_key.pem")

    signed = OpenSSL::PKCS7::sign(
        OpenSSL::X509::Certificate.new(owums_cert),
        OpenSSL::PKey::RSA.new(owums_key, ''),
        prepared[:values].map { |k, v| "#{k}=#{v}" }.join("\n"),
        [],
        OpenSSL::PKCS7::BINARY
    )

    [ prepared[:paypal_base_url],
      OpenSSL::PKCS7::encrypt(
          [OpenSSL::X509::Certificate.new(paypal_cert)],
          signed.to_der,
          OpenSSL::Cipher::Cipher::new("DES3"),
          OpenSSL::PKCS7::BINARY
      ).to_s.gsub("\n", "")
    ]
  end
  
  #def retrieve_gestpay_url
  #  # retrieves url saved before
  #  matches = /<gestpay>(.*)<\/gestpay>/i.match(self.notes)
  #  # return match or nil
  #  unless matches.nil?
  #    matches[1]
  #  end
  #end
  
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
    # if credit card looks valid proceed to bank gateway
    if credit_card.valid?
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
      # execute a SOAP request to call the "callPagamS2S" action
      response = client.request(:call_pagam_s2_s) do
        soap.body = params
      end
      # convert response to hash
      response = response.to_hash[:call_pagam_s2_s_response][:call_pagam_s2_s_result][:gest_pay_s2_s]
      response[:datetime] = time
      # if verification and payment succeded
      if response[:transaction_result] == 'OK':
        # save bank response (shop_transaction, authorization_code) and verify user
        self.set_credit_card_info(response)
        self.credit_card_identity_verify!
        #self.captive_portal_login(request.remote_ip)
      end
      # verified by visa case
      if response[:error_code] == '8006'
        response[:shop_transaction_id] = shop_transaction_id
        # save shop_transaction_id, transaction_key and vbv_risp in DB
        self.set_credit_card_info(response)
        # prolong account validity so it won't expire while the user is verifying
        self.created_at = time
        # temporarily set the user as verified in order to be able to log her in just for the time necessary to complete the payment
        self.verified = true
        self.save!
        # temporarily login user
        response = self.captive_portal_login(request.remote_ip, timeout=true, config_check=false)
        if response.code != "200"
          Rails.logger.error(params.to_json)
          raise 'captive portal login failed for verified_by_visa credit card user with error %s: %s' % [response.code, response.body]
        end
        # unverify user
        self.verified = false
        self.save!
        # add some keys to response hash
        response[:a] = params[:shopLogin]
        response[:b] = response[:vb_v][:vb_v_risp]
        response[:url] = Configuration.get('gestpay_vbv_url')
      end
      # explicit return just for clarity
      return response
    end
    # emulate gestpay response
    return { :transaction_result => 'KO', :error_description => I18n.t(:Credit_card_invalid), :error_code => false }
  end
  
  def gestpay_s2s_verified_by_visa(pares)
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
    
    if response[:transaction_result] == 'OK':
      response[:datetime] = credit_card_info['datetime']
      response[:transaction_key] = credit_card_info['transaction_key']
      response[:VbVRisp] = credit_card_info['VbVRisp']
      self.set_credit_card_info(response)
      self.credit_card_identity_verify!
      #self.captive_portal_login(request.remote_ip)
    end
    return response
  end

  private

  def set_username_if_required
    #if Configuration.get('use_mobile_phone_as_username')
    #  Rails.logger.warn "Deprecation warning: 'use_mobile_phone_as_username' configuration key will be soon removed. Please use 'use_automatic_username' instead"
    #end

    if Configuration.get('use_mobile_phone_as_username') == "true"
      if verify_with_mobile_phone?
        self.username = mobile_phone
      end
    end

  end

  def prepare_paypal_payment(return_url, notify_url)
    values = {
      :business => Configuration.get("paypal_business_account"),
      :cmd => '_cart',
      :upload => 1,
      :return => return_url,
      :invoice => self.id,
      :notify_url => notify_url,
      :currency_code => Configuration.get("paypal_currency", "EUR"),
      :lc => I18n.locale.to_s.upcase
    }

    values.merge!({
      "amount_1" => Configuration.get("credit_card_verification_cost"),
      "item_name_1" => I18n.t(:credit_card_item_name),
      "item_number_1" => self.id,
      "quantity_1" => 1
    })

    if Rails.env.production?
      paypal_base_url = Configuration.get("ipn_url")
    else
      paypal_base_url = Configuration.get("sandbox_ipn_url")
    end

    {:paypal_base_url => paypal_base_url, :values => values}
  end
  
  #def prepare_gestpay_payment()
  #  if self.verify_with_gestpay? and !self.verified
  #    url = self.retrieve_gestpay_url
  #    if url.nil?
  #      # generate and return url (saves to notes)
  #      encrypt_gestpay()
  #    end
  #  end
  #end
  
  #def encrypt_gestpay()  
  #  # import ruby soap library
  #  require 'savon'
  #  
  #  # config
  #  webservice_url = Configuration.get("gestpay_webservice_url")
  #  shop_login = Configuration.get("gestpay_shoplogin")
  #  payment_url = Configuration.get("gestpay_payment_url")
  #  # base url
  #  server = Configuration.get("notifier_base_url")
  #  # transaction id: id+datetime hashed, positive numbers only
  #  transaction_id = (('%s+%s' % [self.id, DateTime.now]).hash.abs).to_s
  #  # user id
  #  # I had to convert self.id to string because something was converting it to a different!
  #  user_id = self.id.to_s
  #  
  #  # init SOAP client
  #  client = Savon.client(webservice_url)
  #
  #  # execute a SOAP request to call the "encrypt" action
  #  response = client.request(:encrypt) do
  #    soap.body = {
  #      :shopLogin => shop_login,
  #      :uicCode => Configuration.get("gestpay_currency", "242"),
  #      :amount => Configuration.get("credit_card_verification_cost", "1"),
  #      :shopTransactionId => transaction_id,
  #      :buyerName => '%s %s' % [self.given_name, self.surname],
  #      :buyerEmail => self.email,
  #      :customInfo => 'USERID=%s*P1*SERVER=%s' % [user_id, server]
  #    }
  #  end
  #  
  #  encrypted_string = response.body[:encrypt_response][:encrypt_result][:gest_pay_crypt_decrypt][:crypt_decrypt_string]
  #  
  #  # return URL in the form of "https://<PAYMENT_URL>?a=<SHOP_LOGIN>&b=<ENCRYPTED_STRING>"
  #  url = "#{payment_url}?a=#{shop_login}&b=#{encrypted_string}"
  #  
  #  # append url in notes and save
  #  self.notes = self.notes.to_s.concat('<gestpay>%s</gestpay>' % url)
  #  self.save!
  #  return url
  #end
  
  # static method
  #def self.validate_gestpay_payment(shop_login, encrypted_string)
  #  # validates a payment done through the Gestpay banking system
  #
  #  # config
  #  webservice_url = Configuration.get("gestpay_webservice_url")
  #  
  #  # import ruby soap library
  #  require 'savon'
  #  
  #  # init SOAP client
  #  client = Savon.client(webservice_url)
  #  
  #  # xml - why? Because by using plain savon code didn't work
  #  xml = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ecom="https://ecomm.sella.it/">
  #  <soapenv:Header/>
  #    <soapenv:Body>
  #      <ecom:Decrypt>
  #         <ecom:shopLogin>%s</ecom:shopLogin>
  #         <ecom:CryptedString>%s</ecom:CryptedString>
  #      </ecom:Decrypt>
  #    </soapenv:Body>
  #  </soapenv:Envelope>' % [shop_login, encrypted_string]
  #  # strip new lines
  #  xml = xml.gsub!("\n", '')
  #  
  #  response = client.request :decrypt do
  #    soap.xml = xml
  #  end
  #  
  #  # convert useful bits of the response to hash
  #  response_hash = response[:decrypt_response][:decrypt_result].to_hash
  #  # get only the part we need, but because there might be some differences between the demo and the real env we need to do a quick check
  #  decrypted = response_hash.has_key?(:gest_pay_s2_s) ? response_hash[:gest_pay_s2_s] : response_hash[:gest_pay_crypt_decrypt]
  #  
  #  # DEBUG
  #  # maybe it shouldn't be DEBUG only
  #  if Rails.env.development?
  #    Rails.logger.warn(response[:decrypt_response][:decrypt_result].to_json)
  #  end
  #  
  #  #success
  #  if decrypted[:transaction_result] == 'OK'
  #    # retrieve params
  #    params = decrypted[:custom_info].split("*P1*")
  #    # init vars
  #    server = ''
  #    user_id = ''
  #    # extract params from custom_info
  #    params.each do |param|
  #      if param.include?('SERVER=')
  #        server = param.sub('SERVER=','')
  #      elsif param.include?('USERID=')
  #        user_id = param.sub('USERID=','')
  #      end
  #    end
  #    
  #    # if the server param is correct
  #    if server == Configuration.get('notifier_base_url')
  #      # retrieve account
  #      user = User.find(user_id)
  #      # activate user account
  #      user.credit_card_identity_verify!
  #      # once validated clear notes field
  #      user.clear_gestpay_notes
  #      user.save!
  #    end
  #  # error
  #  else
  #    # log error
  #    Rails.logger.error("Gestpay payment validation unsuccessful: #{encrypted_string}")
  #  end
  #  
  #  response
  #end

  # Validations
  def valid_captcha?
    if(Configuration.get('captcha_enabled', 'true') == 'true')
      # Redefines method from easy_captcha to
      # use custom error message
      errors.add(:captcha, :invalid_captcha) if @captcha.blank? or @captcha_verification.blank? or @captcha.to_s.upcase != @captcha_verification.to_s.upcase
    end
  end
end
