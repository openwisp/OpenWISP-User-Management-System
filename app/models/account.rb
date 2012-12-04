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
  after_save :prepare_gestpay_payment

  # If the configuration key use_automatic_username is set to true, the username is automatically set
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

  # TODO GESTPAY EDIT:
  # pheraphs this should be renamed to verify_with_paypal
  def verify_with_credit_card(return_url, notify_url)
    prepared = prepare_paypal_payment(return_url, notify_url)
    prepared[:paypal_base_url]+ '?' + prepared[:values].map { |k,v| "#{k}=#{v}"  }.join("&")
  end

  # TODO GESTPAY EDIT:
  # pheraphs this should be renamed to encrypted_verify_with_paypal
  def encrypted_verify_with_credit_card(return_url, notify_url)
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
  
  def retrieve_gestpay_url
    # retrieves url saved before
    matches = /<gestpay>(.*)<\/gestpay>/i.match(self.notes)
    # return match or nil
    unless matches.nil?
      matches[1]
    end
  end
  
  def clear_gestpay_url
    self.notes = self.notes.gsub(/<gestpay>(.*)<\/gestpay>/i, '')
  end

  private

  def set_username_if_required
    if Configuration.get('use_mobile_phone_as_username')
      Rails.logger.warn "Deprecation warning: 'use_mobile_phone_as_username' configuration key will be soon removed. Please use 'use_automatic_username' instead"
    end

    # Retro-compatibility...  "use_mobile_phone_as_username" is deprecated
    if Configuration.get('use_automatic_username') == "true" or Configuration.get('use_mobile_phone_as_username') == "true"
      if verify_with_mobile_phone?
        self.username = mobile_phone
      else
        self.username = email
      end
    end

  end

  def prepare_paypal_payment(return_url, notify_url)
    values = {
      # TODO GESTPAY EDIT:
      # pheraphs credit_card should be renamed to paypal_business_account
      :business => Configuration.get("credit_card_business_account"),
      :cmd => '_cart',
      :upload => 1,
      :return => return_url,
      :invoice => self.id,
      :notify_url => notify_url,
      :currency_code => "EUR",
      :lc => I18n.locale.to_s.upcase
    }

    values.merge!({
      # TODO GESTPAY EDIT:
      # decide if credit_card_verification_cost should be shared between paypal and gestpay
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
  
  def prepare_gestpay_payment()
    if self.verify_with_gestpay?
      url = self.retrieve_gestpay_url
      if url.nil?
        # generate and return url (saves to notes)
        encrypt_gestpay()
      end
    end
  end
  
  def encrypt_gestpay()  
    # import ruby soap library
    require 'savon'
    
    # config
    webservice_url = Configuration.get("gestpay_webservice_url")
    shop_login = Configuration.get("gestpay_shoplogin")
    payment_url = Configuration.get("gestpay_payment_url")
    # base url
    server = Configuration.get("notifier_base_url")
    # transaction id: id+datetime hashed, positive numbers only
    transaction_id = (('%s+%s' % [self.id, DateTime.now]).hash.abs).to_s
    # user id
    # I had to convert self.id to string because something was converting it to a different!
    user_id = self.id.to_s
    
    # init SOAP client
    client = Savon.client(webservice_url)

    # execute a SOAP request to call the "encrypt" action
    response = client.request(:encrypt) do
      soap.body = {
        :shopLogin => shop_login,
        :uicCode => Configuration.get("gestpay_currency"),
        # TODO GESTPAY EDIT:
        # decide if credit_card_verification_cost should be shared between paypal and gestpay
        :amount => Configuration.get("credit_card_verification_cost"),
        :shopTransactionId => transaction_id,
        :buyerName => '%s %s' % [self.given_name, self.surname],
        :buyerEmail => self.email,
        :customInfo => 'USERID=%s*P1*SERVER=%s' % [user_id, server]
      }
    end
    
    encrypted_string = response.body[:encrypt_response][:encrypt_result][:gest_pay_crypt_decrypt][:crypt_decrypt_string]
    
    # return URL in the form of "https://<PAYMENT_URL>?a=<SHOP_LOGIN>&b=<ENCRYPTED_STRING>"
    url = "#{payment_url}?a=#{shop_login}&b=#{encrypted_string}"
    
    # append url in notes and save
    self.notes = self.notes.to_s.concat('<gestpay>%s</gestpay>' % url)
    self.save!
    return url
  end
  
  # static method
  def self.validate_gestpay_payment(shop_login, encrypted_string)
    # validates a payment done through the Gestpay banking system

    # config
    webservice_url = Configuration.get("gestpay_webservice_url")
    
    # import ruby soap library
    require 'savon'
    
    # init SOAP client
    client = Savon.client(webservice_url)
    
    # TODO GESTPAY: try savon order! 
    # xml - why? Because by using plain savon code it didn't work
    xml = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ecom="https://ecomm.sella.it/">
    <soapenv:Header/>
      <soapenv:Body>
        <ecom:Decrypt>
           <ecom:shopLogin>%s</ecom:shopLogin>
           <ecom:CryptedString>%s</ecom:CryptedString>
        </ecom:Decrypt>
      </soapenv:Body>
    </soapenv:Envelope>' % [shop_login, encrypted_string]
    # strip new lines
    xml = xml.gsub!("\n", '')
    
    response = client.request :decrypt do
      soap.xml = xml
    end
    
    decrypted = response[:decrypt_response][:decrypt_result][:gest_pay_s2_s]
    
    # DEBUG
    # maybe it shouldn't be DEBUG only
    if Rails.env.development?
      Rails.logger.warn(response[:decrypt_response][:decrypt_result].to_json)
    end
    
    #success
    if decrypted[:transaction_result] == 'OK'
      # retrieve params
      params = decrypted[:custom_info].split("*P1*")
      # init vars
      server = ''
      user_id = ''
      # extract params from custom_info
      params.each do |param|
        if param.include?('SERVER=')
          server = param.sub('SERVER=','')
        elsif param.include?('USERID=')
          user_id = param.sub('USERID=','')
        end
      end
      
      # if the server param is correct
      if server == Configuration.get('notifier_base_url')
        # retrieve account
        account = User.find(user_id)
        # activate user account
        account.credit_card_identity_verify!
        # once validated clear notes field
        account.clear_gestpay_url
        account.save!
      end
    # error
    else
      # log error
      Rails.logger.error("Gestpay payment validation unsuccessful: #{encrypted_string}")
    end
    
    response
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
