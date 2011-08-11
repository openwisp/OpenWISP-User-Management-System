class CreateMobilePrefixes < ActiveRecord::Migration
  def self.up
    create_table :mobile_prefixes do |t|
      t.integer :prefix,                :null => false
      t.integer :international_prefix,  :null => true
      t.boolean :disabled,              :null => false, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :mobile_prefixes
  end
end
