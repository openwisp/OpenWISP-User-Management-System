class CreateRadiusGroupsUsers < ActiveRecord::Migration
  def self.up
    create_table :radius_groups_users, {:id => false, :force => true} do |t|
      t.belongs_to :user
      t.belongs_to :radius_group

      t.timestamps
    end

    add_index :radius_groups_users, :user_id
    add_index :radius_groups_users, :radius_group_id
  end

  def self.down
    drop_table :radius_groups_users
  end
end
