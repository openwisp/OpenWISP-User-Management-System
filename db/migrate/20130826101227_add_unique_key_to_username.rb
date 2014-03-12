class AddUniqueKeyToUsername < ActiveRecord::Migration
  def self.up
    # ignore errors in case index was not there (it might happen)
    begin
      remove_index :users, :name => :index_users_on_username
    rescue
      nil
    end
    add_index :users, :username, :unique => true
  end

  def self.down
    remove_index :users, :name => :index_users_on_username
    add_index :users, :username
  end
end
