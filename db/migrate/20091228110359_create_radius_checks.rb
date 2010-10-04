class CreateRadiusChecks < ActiveRecord::Migration
  def self.up
    create_table :radius_checks do |t|
      t.string :attribute,  :null => false
      t.string :op,         :null => false, :default => ':='
      t.string :value,      :null => false

      t.references :radius_entity, :polymorphic => true

      t.timestamps
    end

    add_index :radius_checks, [ :radius_entity_id, :radius_entity_type ]
  end

  def self.down
    drop_table :radius_checks
  end
end
