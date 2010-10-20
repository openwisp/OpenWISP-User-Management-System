# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

######################################## OPERATORS SEED START ###################################################################################
#Clean up Operator model...
puts "Cleaning up Operator model (delete_all)..."
Operator.delete_all

# Create 'admin' user. Login: 'admin', Password: 'admin' and give it admin powers
puts "Creating admin with password admin and roles 'users_destroyer users_manager users_viewer users_registrant'..."
admin = Operator.new :login => 'admin', :password => 'admin', :password_confirmation => 'admin', :notes => 'admin'
Operator::ROLES.each { |r| admin.has_role! r }
admin.save(false)

# Create 'registrant' user. Login: 'registrant', Password: 'registrant' and give it registrant powers
puts "Creating operator with password operator and role 'users_registrant'..."
registrant = Operator.new :login => 'registrant', :password => 'registrant', :password_confirmation => 'registrant', :notes => 'Registrant operator'
registrant.has_role! 'users_registrant'
registrant.save(false)

# Create 'hd1_operator' user. Login: 'hd1_operator', Password: 'helpdesk1_operator' and give it hd1 powers
puts "Creating hd1_operator with password helpdesk1_operator and role 'users_finder'..."
helpdesk_operator = Operator.new :login => 'hd1_operator', :password => 'helpdesk1_operator', :password_confirmation => 'helpdesk1_operator', :notes => 'Helpdesk1 operator'
%w(users_finder).each { |r| helpdesk_operator.has_role! r }
helpdesk_operator.save(false)

# Create 'hd2_operator' user. Login: 'hd2_operator', Password: 'helpdesk2_operator' and give it registrant powers
puts "Creating hd2_operator with password helpdesk2_operator and role 'users_browser stats_viewer users_registrant'..."
helpdesk2_operator = Operator.new :login => 'hd2_operator', :password => 'helpdesk2_operator', :password_confirmation => 'helpdesk2_operator', :notes => 'Helpdesk2 operator'
%w(stats_viewer users_browser users_manager users_registrant).each { |r| helpdesk2_operator.has_role! r }
helpdesk2_operator.save(false)

# Create 'boss' user. Login: 'boss', Password: 'boss' and give it boss powers
puts "Creating boss with password boss and role 'users_viewer'..."
boss = Operator.new :login => 'boss', :password => 'boss', :password_confirmation => 'boss', :notes => 'Boss'
%w(stats_viewer users_browser).each { |r| boss.has_role! r }
boss.save(false)

######################################## OPERATORS SEED END #####################################################################################
