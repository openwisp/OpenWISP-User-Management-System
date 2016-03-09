class AddRadiusAuthUserFields < ActiveRecord::Migration
  def self.up
    add_column :users,
               :radattribute,
               :string,
               :limit => 30,
               :null => false,
               :default => 'Cleartext-Password'
    add_column :users,
               :op,
               :string,
               :limit => 8,
               :null => false,
               :default => ':='
  end

  def self.down
    remove_column :users, :radattribute
    remove_column :users, :op
  end
end
