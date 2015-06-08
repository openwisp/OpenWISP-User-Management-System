class AddNewConfigurationKeys < ActiveRecord::Migration

  keys = YAML::load(File.open("db/fixtures/configurations.yml"))

  @configurations = [
    keys[59], # custom_account_instructions_en
    keys[61], # logo
    keys[62], # verification_explain_mobile_it
    keys[63], # verification_explain_mobile_en
    keys[64], # verification_explain_creditcard_it
    keys[65], # verification_explain_creditcard_en
    keys[23], # credit_card_verification_tax
    keys[90], # invoice_owner_en
    keys[91], # invoice_owner_it
    keys[92], # invoice_description_en
    keys[93], # invoice_description_it
    keys[94], # invoice_logo
    keys[95], # invoice_owner_email
    keys[96], # invoice_admin_notification_subject_en
    keys[97], # invoice_admin_notification_subject_it
    keys[29], # tax rate
  ]

  def self.up
    @configurations.each do |config|
      if Configuration.get(config['key']).nil?
        Configuration.create(:key => config['key'],
                             :value => config['value'],
                             :system_key => config['system_key'] == 't')
      end
    end

    # rename "custom_account_instructions" to "custom_account_instructions_it"
    c = Configuration.find_by_key('custom_account_instructions')
    unless c.nil?
      c.key = 'custom_account_instructions_it'
      c.save
    end
  end

  def self.down
    @configurations.each do |config|
      c = Configuration.find_by_key(config['key'])
      unless c.nil?
        c.destroy
      end
    end

    # rename "custom_account_instructions_it" to "custom_account_instructions"
    c = Configuration.find_by_key('custom_account_instructions_it')
    unless c.nil?
      c.key = 'custom_account_instructions'
      c.save
    end
  end
end
