class AddRolesToAdmin < ActiveRecord::Migration
  def self.up
    admin = Operator.find_by_login("admin")
    unless admin.roles.include?("registrant_by_nothing")
      admin.roles = admin.roles + ["registrant_by_nothing"]
    end
    unless admin.roles.include?("registrant_by_id_card")
      admin.roles = admin.roles + ["registrant_by_id_card"]
    end
  end 

  def self.down
    admin = Operator.find_by_login("admin")
    if admin.roles.include?("registrant_by_nothing")
      admin.roles = admin.roles.delete_if { |i| i == "registrant_by_nothing" }
    end
    if admin.roles.include?("registrant_by_id_card")
      admin.roles = admin.roles.delete_if { |i| i == "registrant_by_id_card" }
    end
  end
end