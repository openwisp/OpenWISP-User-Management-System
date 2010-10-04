class CreateRadiusGroups < ActiveRecord::Migration
  def self.up
    create_table :radius_groups do |t|
      t.string  :name,      :null => false
      t.integer :priority,  :null => false, :default => 1

      t.timestamps
    end
    
    add_index :radius_groups, :name
  end

  def self.down
    drop_table :radius_groups
  end
end
