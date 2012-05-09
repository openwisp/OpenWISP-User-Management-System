class FixRadiusCheckAndReplyViews < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("drop view radreply")
    ActiveRecord::Base.connection.execute("drop view radcheck;")

    ActiveRecord::Base.connection.execute(<<eoq)
create view radreply as
  select  radius_replies.id as id,
          users.username as 'UserName',
          radius_replies.reply_attribute as 'Attribute',
          radius_replies.op as op,
          radius_replies.value as 'Value'
  from users join radius_replies on users.id = radius_replies.radius_entity_id and radius_replies.radius_entity_type = 'AccountCommon'
  where users.verified = 1 and users.active = 1 and users.eula_acceptance = 1;
eoq

    ActiveRecord::Base.connection.execute(<<eoq)
create view radcheck as
  (select users.id as id,
          users.username as 'UserName',
          'Cleartext-Password' as 'Attribute',
          ':=' as op,
          crypted_password as 'Value'
  from users
  where users.verified = 1 and users.active = 1 and users.eula_acceptance = 1)
UNION
  (select CONCAT(radius_checks.id, users.id) as id,
          users.username as 'UserName',
          radius_checks.check_attribute as 'Attribute',
          radius_checks.op as op,
          radius_checks.value as 'Value'
    from users join radius_checks on users.id = radius_checks.radius_entity_id and radius_checks.radius_entity_type = 'AccountCommon'
    where users.verified = 1 and users.active = 1 and users.eula_acceptance = 1)
;
eoq

  end

  def self.down
    ActiveRecord::Base.connection.execute("drop view radreply")
    ActiveRecord::Base.connection.execute("drop view radcheck;")

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
create view radcheck as
  select  users.id as id,
          users.username as 'UserName',
          'Cleartext-Password' as 'Attribute',
          ':=' as op,
          crypted_password as 'Value'
  from users
  where users.verified = 1 and users.active = 1 and users.eula_acceptance = 1;
eoq

  end
end
