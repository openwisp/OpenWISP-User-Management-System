require 'test_helper'
 
class NotifierTest < ActionMailer::TestCase
  def test_new_account_notification
    #I18n.locale = :es
    
    account = Account.new(
      :given_name => 'Foo',
      :surname => 'Bar',
      :email => 'foo@bar.com',
      :username => 'foobar',
      :password => 'foobarpassword0',
      :mobile_prefix => '334',
      :mobile_suffix => '4254814',
      :verification_method => 'mobile_phone',
      :birth_date => '1980-10-10',
      :address => 'Via dei Tizii 6',
      :city => 'Rome',
      :zip => '00185',
      :state => 'Italy',
      :eula_acceptance => true,
      :privacy_acceptance => true
    )
    assert account.save, 'could not save new account'
    
    email = Notifier.new_account_notification(account).deliver
    assert !ActionMailer::Base.deliveries.empty?
    
    assert_equal [account.email], email.to, "email to field mismatch"
    assert_equal Configuration.get("account_notification_subject_#{I18n.locale}"), email.subject, "email subject mismatch"
    
    host = Configuration.get('notifier_base_url')
    protocol  =  Configuration.get('notifier_protocol')
    baseurl = '%s://%s' % [protocol, host]
    
    dictionary = {
      :first_name => account.given_name,
      :last_name => account.surname,
      :username => account.username,
      :password_reset_url => "#{baseurl}/account/reset",
      :account_url => "#{baseurl}/account",
      :invoice_message => ''
    }
    
    message = Configuration.get("account_notification_message_#{I18n.locale}")
    
    dictionary.each do |key, value|
      message = message.gsub("{%s}" % key.to_s, value.to_s)
    end
    
    assert_match(message, email.body)
  end
  
  def test_new_account_notification_es
    I18n.locale = 'es'
    
    account = Account.new(
      :given_name => 'Foo',
      :surname => 'Bar',
      :email => 'foo@bar.com',
      :username => 'foobar',
      :password => 'foobarpassword0',
      :mobile_prefix => '334',
      :mobile_suffix => '4254814',
      :verification_method => 'mobile_phone',
      :birth_date => '1980-10-10',
      :address => 'Via dei Tizii 6',
      :city => 'Rome',
      :zip => '00185',
      :state => 'Italy',
      :eula_acceptance => true,
      :privacy_acceptance => true
    )
    assert account.save, 'could not save new account'
    
    email = Notifier.new_account_notification(account).deliver
    assert !ActionMailer::Base.deliveries.empty?
    
    assert_equal [account.email], email.to, "email to field mismatch"

    I18n.locale = 'en'
  end
  
  def test_send_invoice
    assert ActionMailer::Base.deliveries.empty?
    
    # create invoice in DB
    invoice = Invoice.create_for_user(users(:creditcard))
    # generate PDF
    filename = invoice.generate_pdf()
    
    email = Notifier.send_invoice_to_admin(filename).deliver
    
    assert !ActionMailer::Base.deliveries.empty?
    assert email.has_attachments?
    
    email_length = ActionMailer::Base.deliveries.length
    
    email = Notifier.new_account_notification(users(:creditcard), filename).deliver
    assert email.has_attachments?
    assert_equal email_length+1, ActionMailer::Base.deliveries.length
  end
end