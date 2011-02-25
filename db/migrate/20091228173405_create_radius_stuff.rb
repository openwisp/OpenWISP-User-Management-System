# WARNING: the following stuff is mostly MySQL dependent!

class CreateRadiusStuff < ActiveRecord::Migration
  def self.up
    create_table :radacct, { :id => false } do |t|
      t.integer :RadAcctId,           							 :null => false
      t.string :AcctSessionId,        :limit => 32,  :null => false, :default => ''
      t.string :AcctUniqueId,         :limit => 32,  :null => false, :default => ''
      t.string :UserName,             :limit => 64,  :null => false, :default => ''
      t.string :Realm,                :limit => 64,  :default => ''
      t.string :NASIPAddress,         :limit => 15,  :null => false, :default => ''
      t.string :NASPortId,            :limit => 15,  :null => true
      t.string :NASPortType,          :limit => 32,  :null => false, :default => ''
      t.datetime :AcctStartTime,                     :null => false, :default => '0000-00-00 00:00:00'
      t.datetime :AcctStopTime,                      :null => true,  :default => '0000-00-00 00:00:00'
      t.integer :AcctSessionTime,     							 :null => true
      t.string :AcctAuthentic,        :limit => 32,  :null => true
      t.string :ConnectInfo_start,    :limit => 50,  :null => true
      t.string :ConnectInfo_stop,     :limit => 50,  :null => true
      t.integer :AcctInputOctets,     							 :null => true
      t.integer :AcctOutputOctets,    							 :null => true
      t.string :CalledStationId,      :limit => 50,  :null => false, :default => ''
      t.string :CallingStationId,     :limit => 50,  :null => false, :default => ''
      t.string :AcctTerminateCause,   :limit => 32,  :null => false, :default => ''
      t.string :ServiceType,          :limit => 32,  :null => true
      t.string :FramedProtocol,       :limit => 32,  :null => true
      t.string :FramedIPAddress,      :limit => 15,  :null => false, :default => ''
      t.integer :AcctStartDelay,      							 :null => true
      t.integer :AcctStopDelay,       							 :null => true
      t.string :XAscendSessionSvrKey, :limit => 10,  :null => true
    end
    
    ActiveRecord::Base.connection.execute("ALTER TABLE radacct ADD PRIMARY KEY (RadAcctId)")
    ActiveRecord::Base.connection.execute("ALTER TABLE radacct MODIFY RadAcctId BIGINT(21) AUTO_INCREMENT")
    ActiveRecord::Base.connection.execute("ALTER TABLE radacct MODIFY AcctInputOctets BIGINT(20)")
    ActiveRecord::Base.connection.execute("ALTER TABLE radacct MODIFY AcctOutputOctets BIGINT(20)")
    ActiveRecord::Base.connection.execute("ALTER TABLE radacct MODIFY AcctSessionTime INT(12)")
    ActiveRecord::Base.connection.execute("ALTER TABLE radacct MODIFY AcctStartDelay INT(12)")
    ActiveRecord::Base.connection.execute("ALTER TABLE radacct MODIFY AcctStopDelay INT(12)")
    
    add_index :radacct, :UserName
    add_index :radacct, :FramedIPAddress
    add_index :radacct, :AcctSessionId
    add_index :radacct, :AcctUniqueId
    add_index :radacct, :AcctStartTime
    add_index :radacct, :AcctStopTime
    add_index :radacct, :NASIPAddress
    add_index :radacct, :CallingStationId
    
    create_table :dictionary do |t|
      t.string :Type,                 :limit => 30,  :null => true
      t.string :Attribute,            :limit => 64,  :null => true
      t.string :Value,                :limit => 64,  :null => true
      t.string :Format,               :limit => 20,  :null => true
      t.string :Vendor,               :limit => 10,  :null => true
      t.string :RecommendedOp,        :limit => 32,  :null => true
      t.string :RecommendedTable,     :limit => 32,  :null => true
      t.string :RecommendedHelper,    :limit => 32,  :null => true
      t.string :RecommendedTooltip,   :limit => 512, :null => true
    end

    create_table :nas do |t|
      t.string :nasname,              :limit => 128, :null => false
      t.string :shortname,            :limit => 32,  :null => true
      t.string :type,                 :limit => 30,  :null => false, :default => 'other'
      t.integer :ports,               							 :null => true
      t.string :secret,               :limit => 60,  :null => false
      t.string :community,            :limit => 50,  :null => true
      t.string :description,          :limit => 200, :null => true, :default => 'Radius Client'
    end

    add_index :nas, :nasname
    add_index :nas, :shortname
    
    # Create radius views
    ActiveRecord::Base.connection.execute(<<eoq)
create view radcheck as 
  select  users.id as id,
          users.username as 'UserName', 
          'Cleartext-Password' as 'Attribute', 
          ':=' as op, 
          crypted_password as 'Value'
  from users
  where users.verified = 1 and users.active = 1 and users.eula_acceptance = 1;
eoq

    ActiveRecord::Base.connection.execute(<<eoq)
create view radgroupcheck as 
  select  radius_checks.id as id,
          radius_groups.name as 'GroupName', 
          radius_checks.attribute as 'Attribute', 
          radius_checks.op as op, 
          radius_checks.value as 'Value'
  from radius_checks join radius_groups on radius_groups.id = radius_checks.radius_entity_id and radius_checks.radius_entity_type = 'RadiusGroup';
eoq

    ActiveRecord::Base.connection.execute(<<eoq)
create view radreply as 
  select  radius_replies.id as id,
          users.username as 'UserName',
          radius_replies.attribute as 'Attribute', 
          radius_replies.op as op, 
          radius_replies.value as 'Value' 
  from users join radius_replies on users.id = radius_replies.radius_entity_id and radius_replies.radius_entity_type = 'User'
  where users.verified = 1 and users.active = 1 and users.eula_acceptance = 1;
eoq

    ActiveRecord::Base.connection.execute(<<eoq)
create view radgroupreply as 
  select  radius_replies.id as id,
          radius_groups.name as 'GroupName', 
          radius_replies.attribute as 'Attribute', 
          radius_replies.op as op, 
          radius_replies.value as 'Value'
  from radius_replies join radius_groups on radius_groups.id = radius_replies.radius_entity_id and radius_replies.radius_entity_type = 'RadiusGroup';
eoq

    # For freeradius 2
    ActiveRecord::Base.connection.execute(<<eoq)
create view radusergroup as 
  select  users.username as 'UserName', 
          radius_groups.name as 'GroupName', 
          '1' as priority 
  from users join radius_groups_users on users.id = radius_groups_users.user_id join radius_groups on radius_groups_users.radius_group_id = radius_groups.id
  where verified = 1 and users.active = 1 and users.eula_acceptance = 1;
eoq

    # Older freeradius versions
    ActiveRecord::Base.connection.execute(<<eoq)
create view usergroup as 
  select  users.username as 'UserName', 
          radius_groups.name as 'GroupName', 
          '1' as priority 
  from users join radius_groups_users on users.id = radius_groups_users.user_id join radius_groups on radius_groups_users.radius_group_id = radius_groups.id
  where verified = 1 and users.active = 1 and users.eula_acceptance = 1;
eoq

  end

  def self.down
    ActiveRecord::Base.connection.execute("drop view radcheck")
    ActiveRecord::Base.connection.execute("drop view radgroupcheck;")
    ActiveRecord::Base.connection.execute("drop view radreply")
    ActiveRecord::Base.connection.execute("drop view radgroupreply;")
    ActiveRecord::Base.connection.execute("drop view radusergroup;")
    ActiveRecord::Base.connection.execute("drop view usergroup;")
    
    drop_table :radacct
    drop_table :dictionary
    drop_table :nas
  end
end
