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

  def verify_with_credit_card(return_url, notify_url)
    prepared = prepare_paypal_payment(return_url, notify_url)
    prepared[:paypal_base_url]+ '?' + prepared[:values].map { |k,v| "#{k}=#{v}"  }.join("&")
  end

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

  # Validations
  def valid_captcha?
    if(Configuration.get('captcha_enabled', 'true') == 'true')
      # Redefines method from easy_captcha to
      # use custom error message
      errors.add(:captcha, :invalid_captcha) if @captcha.blank? or @captcha_verification.blank? or @captcha.to_s.upcase != @captcha_verification.to_s.upcase
    end
  end
end
