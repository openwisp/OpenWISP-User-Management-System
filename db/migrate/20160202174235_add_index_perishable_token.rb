class AddIndexPerishableToken < ActiveRecord::Migration
  def self.up
    add_index :users, :perishable_token
  end

  def self.down
    remove_index :users, :perishable_token
  end
end
