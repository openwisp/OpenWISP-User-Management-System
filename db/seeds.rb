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
admin = Operator.create! :login => 'admin', :password => 'admin', :password_confirmation => 'admin', :notes => 'admin'
Operator::ROLES.each { |r| admin.has_role! r }

# Create 'registrant' user. Login: 'registrant', Password: 'registrant' and give it registrant powers
puts "Creating operator with password operator and role 'users_registrant'..."
registrant = Operator.create! :login => 'registrant', :password => 'registrant', :password_confirmation => 'registrant', :notes => 'Registrant operator'
registrant.has_role! 'users_registrant'

# Create 'helpdesk_operator' user. Login: 'helpdesk_operator', Password: 'helpdesk_operator' and give it registrant powers
puts "Creating helpdesk_operator with password helpdesk_operator and role 'users_manager users_viewer users_registrant'..."
helpdesk_operator = Operator.create! :login => 'helpdesk_operator', :password => 'helpdesk_operator', :password_confirmation => 'helpdesk_operator', :notes => 'Helpdesk operator'
%w(users_manager users_viewer users_registrant).each { |r| helpdesk_operator.has_role! r }

# Create 'boss' user. Login: 'boss', Password: 'boss' and give it boss powers
puts "Creating boss with password boss and role 'users_viewer'..."
boss = Operator.create! :login => 'boss', :password => 'boss', :password_confirmation => 'boss', :notes => 'Boss'
boss.has_role! 'users_viewer'

######################################## OPERATORS SEED END #####################################################################################
