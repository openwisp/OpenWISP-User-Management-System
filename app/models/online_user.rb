class OnlineUser < User
  default_scope :joins => :radius_accountings,
    :conditions => "AcctStopTime = '0000-00-00 00:00:00' OR AcctStopTime is NULL",
    :order => "AcctStartTime DESC"
end
