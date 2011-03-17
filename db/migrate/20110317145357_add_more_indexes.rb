class AddMoreIndexes < ActiveRecord::Migration
  def self.up
    add_index :mobile_prefixes, :disabled
    add_index :mobile_prefixes, :prefix
    add_index :countries, :disabled
    add_index :simple_captcha_data, :key
    add_index :simple_captcha_data, :updated_at
    add_index :users, :email
    add_index :users, :single_access_token
    add_index :users, :perishable_token
    add_index :users, :updated_at
  end

  def self.down
    remove_index :mobile_prefixes, :disabled
    remove_index :mobile_prefixes, :prefix
    remove_index :countries, :disabled
    remove_index :simple_captcha_data, :key
    remove_index :simple_captcha_data, :updated_at
    remove_index :users, :email
    remove_index :users, :single_access_token
    remove_index :users, :perishable_token
    remove_index :users, :updated_at
  end
end
