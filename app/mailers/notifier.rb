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

  def new_account_notification(account, filename=false)
    subject = Configuration.get("account_notification_subject_#{I18n.locale}")
    if subject.nil?
      subject = Configuration.get("account_notification_subject_en")
    end
    
    message = Configuration.get("account_notification_message_#{I18n.locale}")
    if message.nil?
      message = Configuration.get("account_notification_message_en")
    end
    
    invoice_message = nil
    
    if filename
      attachments[filename.split('/')[-1]] = File.read(filename)
      invoice_message = I18n.t(:account_notification_invoice_message)
    end
    
    baseurl = '%s://%s' % [default_url_options[:protocol], default_url_options[:host]]
    
    dictionary = {
      :first_name => account.given_name,
      :last_name => account.surname,
      :username => account.username,
      :account_url => "#{baseurl}/account",
      :password_reset_url => "#{baseurl}/account/reset",
      :invoice_message => invoice_message.nil? ? '' : "\n%s\n" % invoice_message
    }
    
    @mutex = Mutex.new
    @mutex.synchronize do
      dictionary.each do |key, value|
        # replace placeholders with dynamic values unless value is nil
        message = message.gsub("{%s}" % key.to_s, value.nil? ? '' : value.to_s)
      end
    end
    
    mail(:to => account.email, :subject => subject) do |format|
      format.text { render :text => message }
    end
  end
  
  def send_invoice_to_admin(filename)
    subject = Configuration.get("invoice_admin_notification_subject_#{I18n.locale}")
    if subject.nil?
      subject = Configuration.get("invoice_admin_notification_subject_en")
    end
    @message = I18n.t(:invoice_admin_notification_message)
    email = Configuration.get('invoice_owner_email')
    
    attachments[filename.split('/')[-1]] = File.read(filename)
    
    mail :to => email, :subject => subject
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