class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string    :email,               :null => false                # optional, you can use login instead, or both
      t.string    :crypted_password,    :null => false                # optional, see below
      t.string    :password_salt,       :null => false                # optional, but highly recommended
      t.string    :persistence_token,   :null => false                # required
      t.string    :single_access_token, :null => false                # optional, see Authlogic::Session::Params
      t.string    :perishable_token,    :null => false                # optional, see Authlogic::Session::Perishability

      # Magic columns, just like ActiveRecord's created_at and updated_at. These are automatically maintained by Authlogic if they are present.
      t.boolean   :active,                              :default => TRUE 	# optional, see Authlogic::Session::MagicColumns
      t.integer   :login_count,         :null => false, :default => 0   	# optional, see Authlogic::Session::MagicColumns
      t.integer   :failed_login_count,  :null => false, :default => 0   	# optional, see Authlogic::Session::MagicColumns
      t.datetime  :last_request_at                                      	# optional, see Authlogic::Session::MagicColumns
      t.datetime  :current_login_at                                     	# optional, see Authlogic::Session::MagicColumns
      t.datetime  :last_login_at                                        	# optional, see Authlogic::Session::MagicColumns
      t.string    :current_login_ip                                     	# optional, see Authlogic::Session::MagicColumns
      t.string    :last_login_ip                                        	# optional, see Authlogic::Session::MagicColumns
      
      
      t.string   :given_name,          :null => false 
      t.string   :surname,             :null => false 
      t.date     :birth_date,          :null => false 
      t.string   :state,               :null => false 
      t.string   :city,                :null => false 
      t.string   :address,             :null => false 
      t.string   :zip,                 :null => false 
      t.string   :username,            :null => false 
      t.string   :mobile_prefix
      t.string   :mobile_suffix
      t.binary   :image_file_data,     :limit => 5.megabyte
      
      t.string   :verification_method, :null => false, :default => 'mobile_phone'
      t.boolean  :verified,                            :default => FALSE
      t.datetime :verified_at
      t.boolean  :recovered,           :null => true
      t.datetime :recovered_at
      t.boolean  :eula_acceptance,     :null => false, :default => FALSE
      t.boolean  :privacy_acceptance,  :null => false, :default => FALSE

      t.timestamps
    end
    
    add_index :users, :username
    add_index :users, :persistence_token
    add_index :users, :last_request_at
    add_index :users, [ :mobile_prefix, :mobile_suffix ]
  end

  def self.down
    drop_table :users
  end
end
  
