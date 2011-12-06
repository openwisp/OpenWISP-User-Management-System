# This file is part of the OpenWISP User Management System
#
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

xml.instruct!
xml.online_users :type => :array do
  @online_users.each do |online_user|
    xml.online_user do
      xml.username online_user.username

      xml.radius_accounting do
        xml.calling_station_id online_user.radius_accountings.last_logins(1).first.calling_station_id
      end
    end
  end
end

