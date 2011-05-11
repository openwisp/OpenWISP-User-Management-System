class OnlineUser < User
  default_scope :joins => :radius_accountings,
    :conditions => "AcctStopTime = '0000-00-00 00:00:00' OR AcctStopTime is NULL",
    :order => "AcctStartTime DESC"

  def to_xml(options={})
    super({ :root => 'online_user' }.merge(options))
  end
end
