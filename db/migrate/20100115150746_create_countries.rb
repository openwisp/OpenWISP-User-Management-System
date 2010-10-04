class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
      t.string :iso,            :null => false
      t.string :iso3,           :null => true
      t.string :name,           :null => false
      t.string :printable_name, :null => false
      t.integer :numcode,       :null => true
      t.boolean :disabled,      :null => false, :default => false

      t.timestamps
    end
    
    add_index :countries, :printable_name
    
  end

  def self.down
    drop_table :countries
  end
end
