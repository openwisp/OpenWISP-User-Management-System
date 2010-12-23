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

class Account < AccountCommon

  # Captcha
  
  apply_simple_captcha :message => I18n.t(:captcha_error), :add_to_base => true

  # Security and cleanup

  attr_readonly  :username, :given_name, :surname, :birth_date, :verification_method

  # Validations
  # # Allowing nil to avoid duplicate error notification (password field is already validated by Authlogic)
  validates_inclusion_of :verification_method, :in => Account::SELFVERIFICATION_METHODS, :if => Proc.new{|account| account.new_record? }

  # Security and cleanup
  attr_protected :verified             # SEC: shouldn't be set with mass-assignment!

  # Utilities
  
  def expire_time
    if self.verified?
      Rails.logger.error("Account already verified")
      raise "Account already verified"
    else
      if self.verification_method == Account::VERIFY_BY_MOBILE
        (Configuration.get('mobile_phone_registration_expire').to_i - (Time.now() - self.created_at).to_i + 60) / 60
      elsif self.verification_method == Account::VERIFY_BY_CREDIT_CARD
        (Configuration.get('credit_card_registration_expire').to_i - (Time.now() - self.created_at).to_i + 60) / 60
      else
        Rails.logger.error("Invalid verification method")
        raise "Invalid verification method"
      end
    end
  end
  
  def ask_for_mobile_phone_password_recovery!
    if self.verification_method == Account::VERIFY_BY_MOBILE
      self.reset_single_access_token
      self.reset_perishable_token
      self.recovered = false
      self.save!
      Rails.logger.info("Recovery asked for an unverified account")
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end
  
  def ask_for_mobile_phone_identity_verification!
    if self.verification_method == Account::VERIFY_BY_MOBILE
      self.verified = false
      self.save!
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def save_from_mobile_phone_password_recovery
    self.reset_single_access_token
    self.reset_perishable_token
    self.save
  end

  def self.find_by_mobile_phone(mobile_phone, params={})
    Account.find(:first, :conditions => [ "CONCAT(mobile_prefix,mobile_suffix) = ?", mobile_phone ])
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
    if self.verification_method == Account::VERIFY_BY_MOBILE
      "#{self.mobile_prefix}#{self.mobile_suffix}"
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end

  def mobile_phone=(value)
    if self.verification_method == Account::VERIFY_BY_MOBILE
      self.mobile_prefix = value[0..2]
      self.mobile_suffix = value[3,-1]
    else
      Rails.logger.error("Verification method is not 'mobile_phone'!")
    end
  end


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

    case RAILS_ENV
    when "development"
      paypal_base_url = Configuration.get("sandbox_ipn_url")
    when "production"
      paypal_base_url = Configuration.get("ipn_url")
    end

    {:paypal_base_url => paypal_base_url, :values => values}
  end

end
