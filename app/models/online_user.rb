class OnlineUser < AccountCommon
  scope :with_accountings, joins(:radius_accountings)
  scope :session_opened, where("AcctStopTime = '0000-00-00 00:00:00' OR AcctStopTime is NULL")

  default_scope session_opened.with_accountings.order("AcctStartTime DESC")
end
