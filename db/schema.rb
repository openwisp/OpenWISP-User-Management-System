# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110317145357) do

  create_table "bdrb_job_queues", :force => true do |t|
    t.text     "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "configurations", :force => true do |t|
    t.string   "key",                          :null => false
    t.text     "value",                        :null => false
    t.boolean  "system_key", :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "configurations", ["key"], :name => "index_configurations_on_key"

  create_table "countries", :force => true do |t|
    t.string   "iso",                               :null => false
    t.string   "iso3"
    t.string   "name",                              :null => false
    t.string   "printable_name",                    :null => false
    t.integer  "numcode"
    t.boolean  "disabled",       :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "countries", ["disabled"], :name => "index_countries_on_disabled"
  add_index "countries", ["printable_name"], :name => "index_countries_on_printable_name"

  create_table "dictionary", :force => true do |t|
    t.string "Type",               :limit => 30
    t.string "Attribute",          :limit => 64
    t.string "Value",              :limit => 64
    t.string "Format",             :limit => 20
    t.string "Vendor",             :limit => 10
    t.string "RecommendedOp",      :limit => 32
    t.string "RecommendedTable",   :limit => 32
    t.string "RecommendedHelper",  :limit => 32
    t.string "RecommendedTooltip", :limit => 512
  end

  create_table "mobile_prefixes", :force => true do |t|
    t.integer  "prefix",                                  :null => false
    t.integer  "international_prefix"
    t.boolean  "disabled",             :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mobile_prefixes", ["disabled"], :name => "index_mobile_prefixes_on_disabled"
  add_index "mobile_prefixes", ["prefix"], :name => "index_mobile_prefixes_on_prefix"

  create_table "nas", :force => true do |t|
    t.string  "nasname",     :limit => 128,                              :null => false
    t.string  "shortname",   :limit => 32
    t.string  "type",        :limit => 30,  :default => "other",         :null => false
    t.integer "ports"
    t.string  "secret",      :limit => 60,                               :null => false
    t.string  "community",   :limit => 50
    t.string  "description", :limit => 200, :default => "Radius Client"
  end

  add_index "nas", ["nasname"], :name => "index_nas_on_nasname"
  add_index "nas", ["shortname"], :name => "index_nas_on_shortname"

  create_table "operators", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "login",                            :null => false
    t.string   "crypted_password",                 :null => false
    t.string   "password_salt",                    :null => false
    t.string   "persistence_token",                :null => false
    t.integer  "login_count",       :default => 0, :null => false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.text     "notes"
  end

  add_index "operators", ["last_request_at"], :name => "index_operators_on_last_request_at"
  add_index "operators", ["login"], :name => "index_operators_on_login"
  add_index "operators", ["persistence_token"], :name => "index_operators_on_persistence_token"

  create_table "operators_roles", :id => false, :force => true do |t|
    t.integer  "operator_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "radacct", :primary_key => "RadAcctId", :force => true do |t|
    t.string   "AcctSessionId",        :limit => 32, :default => "", :null => false
    t.string   "AcctUniqueId",         :limit => 32, :default => "", :null => false
    t.string   "UserName",             :limit => 64, :default => "", :null => false
    t.string   "Realm",                :limit => 64, :default => ""
    t.string   "NASIPAddress",         :limit => 15, :default => "", :null => false
    t.string   "NASPortId",            :limit => 15
    t.string   "NASPortType",          :limit => 32, :default => "", :null => false
    t.datetime "AcctStartTime",                                      :null => false
    t.datetime "AcctStopTime"
    t.integer  "AcctSessionTime"
    t.string   "AcctAuthentic",        :limit => 32
    t.string   "ConnectInfo_start",    :limit => 50
    t.string   "ConnectInfo_stop",     :limit => 50
    t.integer  "AcctInputOctets",      :limit => 8
    t.integer  "AcctOutputOctets",     :limit => 8
    t.string   "CalledStationId",      :limit => 50, :default => "", :null => false
    t.string   "CallingStationId",     :limit => 50, :default => "", :null => false
    t.string   "AcctTerminateCause",   :limit => 32, :default => "", :null => false
    t.string   "ServiceType",          :limit => 32
    t.string   "FramedProtocol",       :limit => 32
    t.string   "FramedIPAddress",      :limit => 15, :default => "", :null => false
    t.integer  "AcctStartDelay"
    t.integer  "AcctStopDelay"
    t.string   "XAscendSessionSvrKey", :limit => 10
  end

  add_index "radacct", ["AcctSessionId"], :name => "index_radacct_on_AcctSessionId"
  add_index "radacct", ["AcctStartTime"], :name => "index_radacct_on_AcctStartTime"
  add_index "radacct", ["AcctStopTime"], :name => "index_radacct_on_AcctStopTime"
  add_index "radacct", ["AcctUniqueId"], :name => "index_radacct_on_AcctUniqueId"
  add_index "radacct", ["CallingStationId"], :name => "index_radacct_on_CallingStationId"
  add_index "radacct", ["FramedIPAddress"], :name => "index_radacct_on_FramedIPAddress"
  add_index "radacct", ["NASIPAddress"], :name => "index_radacct_on_NASIPAddress"
  add_index "radacct", ["UserName"], :name => "index_radacct_on_UserName"

  create_table "radcheck", :id => false, :force => true do |t|
    t.integer "id",                      :default => 0,  :null => false
    t.string  "UserName",                                :null => false
    t.string  "Attribute", :limit => 18, :default => "", :null => false
    t.string  "op",        :limit => 2,  :default => "", :null => false
    t.string  "Value",                                   :null => false
  end

  create_table "radgroupcheck", :id => false, :force => true do |t|
    t.integer "id",        :default => 0,    :null => false
    t.string  "GroupName",                   :null => false
    t.string  "Attribute",                   :null => false
    t.string  "op",        :default => ":=", :null => false
    t.string  "Value",                       :null => false
  end

  create_table "radgroupreply", :id => false, :force => true do |t|
    t.integer "id",        :default => 0, :null => false
    t.string  "GroupName",                :null => false
    t.string  "Attribute",                :null => false
    t.string  "op",                       :null => false
    t.string  "Value",                    :null => false
  end

  create_table "radius_checks", :force => true do |t|
    t.string   "attribute",                            :null => false
    t.string   "op",                 :default => ":=", :null => false
    t.string   "value",                                :null => false
    t.integer  "radius_entity_id"
    t.string   "radius_entity_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "radius_checks", ["radius_entity_id", "radius_entity_type"], :name => "index_radius_checks_on_radius_entity_id_and_radius_entity_type"

  create_table "radius_groups", :force => true do |t|
    t.string   "name",                      :null => false
    t.integer  "priority",   :default => 1, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "radius_groups", ["name"], :name => "index_radius_groups_on_name"

  create_table "radius_groups_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "radius_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "radius_groups_users", ["radius_group_id"], :name => "index_radius_groups_users_on_radius_group_id"
  add_index "radius_groups_users", ["user_id"], :name => "index_radius_groups_users_on_user_id"

  create_table "radius_replies", :force => true do |t|
    t.string   "attribute",          :null => false
    t.string   "op",                 :null => false
    t.string   "value",              :null => false
    t.integer  "radius_entity_id"
    t.string   "radius_entity_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "radius_replies", ["radius_entity_id", "radius_entity_type"], :name => "index_radius_replies_on_radius_entity_id_and_radius_entity_type"

  create_table "radreply", :id => false, :force => true do |t|
    t.integer "id",        :default => 0, :null => false
    t.string  "UserName",                 :null => false
    t.string  "Attribute",                :null => false
    t.string  "op",                       :null => false
    t.string  "Value",                    :null => false
  end

  create_table "radusergroup", :id => false, :force => true do |t|
    t.string "UserName",                               :null => false
    t.string "GroupName",                              :null => false
    t.string "priority",  :limit => 1, :default => "", :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "simple_captcha_data", :force => true do |t|
    t.string   "key",        :limit => 40
    t.string   "value",      :limit => 6
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "simple_captcha_data", ["key"], :name => "index_simple_captcha_data_on_key"
  add_index "simple_captcha_data", ["updated_at"], :name => "index_simple_captcha_data_on_updated_at"

  create_table "usergroup", :id => false, :force => true do |t|
    t.string "UserName",                               :null => false
    t.string "GroupName",                              :null => false
    t.string "priority",  :limit => 1, :default => "", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                                               :null => false
    t.string   "crypted_password",                                                    :null => false
    t.string   "password_salt",                                                       :null => false
    t.string   "persistence_token",                                                   :null => false
    t.string   "single_access_token",                                                 :null => false
    t.string   "perishable_token",                                                    :null => false
    t.boolean  "active",                                  :default => true
    t.integer  "login_count",                             :default => 0,              :null => false
    t.integer  "failed_login_count",                      :default => 0,              :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.string   "given_name",                                                          :null => false
    t.string   "surname",                                                             :null => false
    t.date     "birth_date",                                                          :null => false
    t.string   "state",                                                               :null => false
    t.string   "city",                                                                :null => false
    t.string   "address",                                                             :null => false
    t.string   "zip",                                                                 :null => false
    t.string   "username",                                                            :null => false
    t.string   "mobile_prefix"
    t.string   "mobile_suffix"
    t.binary   "image_file_data",     :limit => 16777215
    t.string   "verification_method",                     :default => "mobile_phone", :null => false
    t.boolean  "verified",                                :default => false
    t.datetime "verified_at"
    t.boolean  "recovered"
    t.datetime "recovered_at"
    t.boolean  "eula_acceptance",                         :default => false,          :null => false
    t.boolean  "privacy_acceptance",                      :default => false,          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["last_request_at"], :name => "index_users_on_last_request_at"
  add_index "users", ["mobile_prefix", "mobile_suffix"], :name => "index_users_on_mobile_prefix_and_mobile_suffix"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"
  add_index "users", ["single_access_token"], :name => "index_users_on_single_access_token"
  add_index "users", ["updated_at"], :name => "index_users_on_updated_at"
  add_index "users", ["username"], :name => "index_users_on_username"

end
