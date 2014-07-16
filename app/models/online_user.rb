# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class OnlineUser < AccountCommon
  scope :with_accountings, joins(:radius_accountings)
  # select radius sessions which are still open but not older than 3 days (because some sessions might be stale)
  # TODO: "AND AcctStartTime >= (NOW() - INTERVAL 3 DAY)" might be removed in the future
  scope :session_opened, where("(AcctStopTime = '0000-00-00 00:00:00' OR AcctStopTime is NULL) AND AcctStartTime >= (NOW() - INTERVAL 3 DAY)")

  # Should never be assigned... (see Account and User classes)
  attr_accessible

  default_scope session_opened.with_accountings.order("AcctStartTime DESC")
end
