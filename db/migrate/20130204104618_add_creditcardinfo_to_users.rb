class AddCreditcardinfoToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :credit_card_info, :text
  end

  def self.down
    remove_column :users, :credit_card_info
  end
end
