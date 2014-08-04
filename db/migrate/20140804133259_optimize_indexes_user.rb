class OptimizeIndexesUser < ActiveRecord::Migration
  def self.up
    # remove indexes that do not add much value
    remove_index :users, :persistence_token
    remove_index :users, :single_access_token
    remove_index :users, :perishable_token
    remove_index :users, :last_request_at
    remove_index :users, :updated_at
    # add indexes that will speed up queries
    add_index :users, :active
    add_index :users, :given_name
    add_index :users, :surname
    add_index :users, :verification_method
    add_index :users, :verified
    add_index :users, :verified_at
  end

  def self.down
    # rollback
    add_index :users, :persistence_token
    add_index :users, :single_access_token
    add_index :users, :perishable_token
    add_index :users, :last_request_at
    add_index :users, :updated_at
    remove_index :users, :active
    remove_index :users, :given_name
    remove_index :users, :surname
    remove_index :users, :verification_method
    remove_index :users, :verified
    remove_index :users, :verified_at
  end
end
