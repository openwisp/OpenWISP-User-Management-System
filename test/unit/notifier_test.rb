require 'test_helper'
 
class NotifierTest < ActionMailer::TestCase
  def test_new_account_notification
    account = Account.new(
      :given_name => 'Foo',
      :surname => 'Bar',
      :email => 'foo@bar.com',
      :username => 'foobar',
      :password => 'foobarpassword0',
      :mobile_prefix => '334',
      :mobile_suffix => '4254804',
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
    
    dictionary = {
      :first_name => account.given_name,
      :last_name => account.surname,
      :username => account.username
    }
    
    message = Configuration.get("account_notification_message_#{I18n.locale}")
    
    dictionary.each do |key, value|
      message.gsub!("{%s}" % key.to_s, value.to_s)
    end
    
    assert_match(message, email.body)
  end
end