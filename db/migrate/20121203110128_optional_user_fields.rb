class OptionalUserFields < ActiveRecord::Migration
  def self.up
    if CONFIG['birth_date'] == false
      change_column :users, "birth_date", :datetime, :null => true
    end
  end

  def self.down
    if CONFIG['birth_date'] == true
      # Make sure no null value exist
      User.update_all({:date_column => Time.now}, {:date_column => nil})
      change_column :users, "birth_date", :datetime, :null => false
    end
  end
end
