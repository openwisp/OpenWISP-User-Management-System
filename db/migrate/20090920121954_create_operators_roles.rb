class CreateOperatorsRoles < ActiveRecord::Migration
  def self.up
    create_table :operators_roles, :id => false, :force => true do |t|
      t.integer  :operator_id
      t.integer  :role_id

      t.timestamps
    end
  end

  def self.down
    drop_table :operators_roles
  end
end
