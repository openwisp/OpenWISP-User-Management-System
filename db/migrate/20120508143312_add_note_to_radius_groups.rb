class AddNoteToRadiusGroups < ActiveRecord::Migration
  def self.up
    add_column :radius_groups, :notes, :text
  end

  def self.down
    remove_column :radius_groups, :notes
  end
end
