# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2010 CASPUR (Davide Guerri d.guerri@caspur.it)
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

class Notifier < ActionMailer::Base  
  default_url_options[:host] = Configuration.get('notifier_base_url')
  default_url_options[:protocol]  =  Configuration.get('notifier_protocol')
  
  def password_reset_instructions(account)
    if Configuration.get('password_reset_custom_url_enabled') == 'true'
      reset_url = Configuration.get('password_reset_custom_url') + account.perishable_token
    else
      reset_url = edit_email_password_reset_url(account.perishable_token)
    end
    
    subject       Configuration.get("password_reset_subject_#{I18n.locale}")
    from          Configuration.get('password_reset_from')
    recipients    account.email  
    sent_on       Time.now  
    body          :edit_password_reset_url => reset_url

  end
end