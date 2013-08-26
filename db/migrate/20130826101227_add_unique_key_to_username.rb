class AddUniqueKeyToUsername < ActiveRecord::Migration
  def self.up
    remove_index :users, :name => :index_users_on_username
    add_index :users, :username, :unique => true
  end
  
  def self.down
    remove_index :users, :name => :index_users_on_username
    add_index :users, :username
  end
end
