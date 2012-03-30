class RenameRadiusAttributeAttribute < ActiveRecord::Migration
  # Renames the attribute named "attribute" because it's nearly impossible to
  # make rails manage a model with this... (see also https://github.com/bjones/safe_attributes)
  #
  # "Caveats
  #  It is virtually impossible to have a column named ‘attribute’ in your schema when using
  #  ActiveRecord. After spending some time trying to make it work I’ve come to the conclusion
  #  the only way to support this will be to change the tactic I’m using entirely, and likely
  #  to get the developers of ActiveRecord to agree to a patch." --bjones

  def self.up
    rename_column :radius_replies, :attribute, :reply_attribute
    rename_column :radius_checks,  :attribute, :check_attribute

    ActiveRecord::Base.connection.execute("drop view radgroupcheck;")
    ActiveRecord::Base.connection.execute("drop view radreply")
    ActiveRecord::Base.connection.execute("drop view radgroupreply;")

    # Create radius views
    ActiveRecord::Base.connection.execute(<<eoq)
create view radgroupcheck as 
  select  radius_checks.id as id,
          radius_groups.name as 'GroupName', 
          radius_checks.check_attribute as 'Attribute', 
          radius_checks.op as op, 
          radius_checks.value as 'Value'
  from radius_checks join radius_groups on radius_groups.id = radius_checks.radius_entity_id and radius_checks.radius_entity_type = 'RadiusGroup';
eoq

    ActiveRecord::Base.connection.execute(<<eoq)
create view radreply as 
  select  radius_replies.id as id,
          users.username as 'UserName',
          radius_replies.reply_attribute as 'Attribute', 
          radius_replies.op as op, 
          radius_replies.value as 'Value' 
  from users join radius_replies on users.id = radius_replies.radius_entity_id and radius_replies.radius_entity_type = 'User'
  where users.verified = 1 and users.active = 1 and users.eula_acceptance = 1;
eoq

    ActiveRecord::Base.connection.execute(<<eoq)
create view radgroupreply as 
  select  radius_replies.id as id,
          radius_groups.name as 'GroupName', 
          radius_replies.reply_attribute as 'Attribute', 
          radius_replies.op as op, 
          radius_replies.value as 'Value'
  from radius_replies join radius_groups on radius_groups.id = radius_replies.radius_entity_id and radius_replies.radius_entity_type = 'RadiusGroup';
eoq
  end

  def self.down
    rename_column :radius_checks,  :check_attribute, :attribute
    rename_column :radius_replies, :reply_attribute, :attribute

    ActiveRecord::Base.connection.execute("drop view radgroupcheck;")
    ActiveRecord::Base.connection.execute("drop view radreply")
    ActiveRecord::Base.connection.execute("drop view radgroupreply;")
    
    # Create radius views
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

  end

end

