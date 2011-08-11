class RemoveTimestampsFromRadiusGroupsUsers < ActiveRecord::Migration
  ### Removed because:
  # Having additional attributes on the join table of a
  # has_and_belongs_to_many association is deprecated and
  # will be removed in Rails 3.1.
  # Please use a has_many :through association instead.

  def self.up
    remove_column :radius_groups_users, :created_at
    remove_column :radius_groups_users, :updated_at
  end

  def self.down
    add_column :radius_groups_users, :created_at, :datetime
    add_column :radius_groups_users, :updated_at, :datetime
  end
end
