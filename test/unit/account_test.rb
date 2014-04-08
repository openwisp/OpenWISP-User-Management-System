require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test "save new account and username checks" do
    a = Account.new(
      :given_name => 'Foo',
      :surname => 'Bar',
      :email => 'foo@bar.com',
      :username => 'foobar',
      :password => 'foobarpassword0',
      :mobile_prefix => '334',
      :mobile_suffix => '4352702',
      :verification_method => 'mobile_phone',
      :birth_date => '1980-10-10',
      :address => 'Via dei Tizii 6',
      :city => 'Rome',
      :zip => '00185',
      :state => 'Italy',
      :eula_acceptance => true,
      :privacy_acceptance => true
    )
    assert a.save, 'could not save new account'
    a.username = ''
    # ensure it doesn't get saved
    assert !a.save, 'empty username has been saved although it should not have been'
    assert a.errors.length <= 1, 'more than 1 errors'
    assert a.errors.has_key?(:username), 'there should be an errror related to the username'
    a.username = 'foo@bar'
    assert !a.save, '@ sign should not be allowed in the username in order to support federation of networks'
    assert a.errors.length <= 1, 'more than 1 errors'
    assert a.errors.has_key?(:username), 'there should be an errror related to the username'
  end
  
  test "generate_invoice!" do
    # set correct webservice method
    Configuration.set('gestpay_webservice_method', 'payment')
    
    # esnure no emails sent yet
    assert ActionMailer::Base.deliveries.empty?
    
    user = users(:creditcard)
    
    # try disabling invoicing
    Configuration.set('gestpay_invoicing_enabled', 'false')
    # ensure result is false
    assert !user.generate_invoice!
    # re-enable invoicing
    Configuration.set('gestpay_invoicing_enabled', 'true')
    
    # ensure invoice is generated
    filepath = user.generate_invoice!
    assert File.exist?(filepath)
    assert !ActionMailer::Base.deliveries.empty?
  end
end