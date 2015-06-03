class CreateSocialAuth < ActiveRecord::Migration
  def self.up
    create_table :social_auths do |t|
      t.string :provider
      t.string :uid
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :social_auths
  end
end
