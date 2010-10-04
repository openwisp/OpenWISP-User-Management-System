class CreateOperators < ActiveRecord::Migration
  def self.up
    create_table :operators do |t|
      t.timestamps
      
      t.string   :login,              :null => false
      t.string   :crypted_password,   :null => false
      t.string   :password_salt,      :null => false
      t.string   :persistence_token,  :null => false
      t.integer  :login_count,        :null => false, :default => 0
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      t.string   :last_login_ip
      t.string   :current_login_ip
      
      t.text     :notes

    end
    
    add_index :operators, :login
    add_index :operators, :persistence_token
    add_index :operators, :last_request_at
    
  end

  def self.down
    drop_table :operators
  end
end
