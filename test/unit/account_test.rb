require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test "save new account" do
    a = Account.new(
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
    assert a.save
  end
  
  test "missing username should fail" do
    # create a new account with missing username
    a = Account.new
    a.given_name = 'Fred'
    a.surname = 'Bar'
    a.email = 'fred.bar@testing.com'
    a.email_confirmation = a.email
    a.password = 'testerpwd3'
    a.password_confirmation = a.password
    a.mobile_prefix = ''
    a.mobile_suffix = ''
    a.mobile_prefix_confirmation = ''
    a.mobile_suffix_confirmation = ''
    a.verification_method = 'gestpay_credit_card'
    a.birth_date = CONFIG['birth_date'] ? '1980-10-10' : ''
    a.address = CONFIG['address'] ? 'Via dei Tizii 6' : ''
    a.city = CONFIG['city'] ? 'Rome' : ''
    a.zip = CONFIG['zip'] ? '00185' : ''
    a.state = 'Italy'
    a.eula_acceptance = true
    a.privacy_acceptance = true
    
    # ensure it doesn't get saved
    assert !a.save
    # there should be only one error related to the missing username
    assert a.errors.length <= 1, 'more than 1 errors'
    assert a.errors.has_key?(:username)
  end
  
  test "check gestpay phase1 is working" do
    # create a new account
    a = Account.new
    a.given_name = 'Fred'
    a.surname = 'Bar'
    a.username = 'tester'
    a.email = 'fred.bar@testing.com'
    a.email_confirmation = a.email
    a.password = 'testerpwd3'
    a.password_confirmation = a.password
    a.mobile_prefix = ''
    a.mobile_suffix = ''
    a.mobile_prefix_confirmation = ''
    a.mobile_suffix_confirmation = ''
    a.verification_method = 'gestpay_credit_card'
    a.birth_date = CONFIG['birth_date'] ? '1980-10-10' : ''
    a.address = CONFIG['address'] ? 'Via dei Tizii 6' : ''
    a.city = CONFIG['city'] ? 'Rome' : ''
    a.zip = CONFIG['zip'] ? '00185' : ''
    a.state = 'Italy'
    a.eula_acceptance = true
    a.privacy_acceptance = true
    
    # save into DB
    assert a.save
    # ensure retrieve_gestpay_url doesn't return nil
    assert !a.retrieve_gestpay_url.nil?
    
    # retrieve parameter B from gestpay_url
    querystring = a.retrieve_gestpay_url.split('?')[1]
    params = querystring.split('&')
    puts params
    b = params[1].gsub('b=', '')
    
    # ensure param b is not empty
    assert !b.empty?
  end
end