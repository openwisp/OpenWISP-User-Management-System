class OptionalUserFields < ActiveRecord::Migration
  def self.up
    change_column :users, "birth_date", :datetime, :null => true
  end

  def self.down
    # Make sure no null value exist
    User.update_all({:date_column => Time.now}, {:date_column => nil})
    change_column :users, "birth_date", :datetime, :null => false
  end
end
