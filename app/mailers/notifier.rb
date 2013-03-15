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

class Notifier < ActionMailer::Base  
  default_url_options[:host] = Configuration.get('notifier_base_url')
  default_url_options[:protocol]  =  Configuration.get('notifier_protocol')

  default :from => Configuration.get('password_reset_from')

  def new_account_notification(account)
    @user = account
    subject = Configuration.get("account_notification_subject_#{I18n.locale}")
    @message = Configuration.get("account_notification_message_#{I18n.locale}")
    
    baseurl = '%s://%s' % [default_url_options[:protocol], default_url_options[:host]]
    
    dictionary = {
      :first_name => @user.given_name,
      :last_name => @user.surname,
      :username => @user.username,
      :account_url => "#{baseurl}/account",
      :password_reset_url => "#{baseurl}/account/reset",
    }
    
    dictionary.each do |key, value|
      @message.gsub!("{%s}" % key.to_s, value.to_s)
    end
    
    mail :to => account.email, :subject => subject
  end

  def password_reset_instructions(account)
    if Configuration.get('password_reset_custom_url_enabled') == 'true'
      @reset_url = Configuration.get('password_reset_custom_url') + account.perishable_token
    else
      @reset_url = edit_email_password_reset_url(account.perishable_token)
    end
    
    mail(:to => account.email, :subject => Configuration.get("password_reset_subject_#{I18n.locale}"))
  end
end