class RemoveTimestampsFromOperatorsRoles < ActiveRecord::Migration
  ### Removed because:
  # Having additional attributes on the join table of a
  # has_and_belongs_to_many association is deprecated and
  # will be removed in Rails 3.1.
  # Please use a has_many :through association instead.

  def self.up
    remove_column :operators_roles, :created_at
    remove_column :operators_roles, :updated_at
  end

  def self.down
    add_column :operators_roles, :created_at, :datetime
    add_column :operators_roles, :updated_at, :datetime
  end
end
