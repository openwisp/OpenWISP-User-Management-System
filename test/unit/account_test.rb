require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  def _init_account()
    Account.new(
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
  end

  test "save new account and username checks" do
    a = _init_account()
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

    a = Account.new(
      :given_name => 'Foo',
      :surname => 'Bar',
      :email => 'foo2@bar.com',
      :username => 'FOOBAR',
      :password => 'foobarpassword0',
      :mobile_prefix => '334',
      :mobile_suffix => '4352703',
      :verification_method => 'mobile_phone',
      :birth_date => '1980-10-10',
      :address => 'Via dei Tizii 6',
      :city => 'Rome',
      :zip => '00185',
      :state => 'Italy',
      :eula_acceptance => true,
      :privacy_acceptance => true
    )
    assert !a.valid?
    assert_equal 1, a.errors.length
    assert a.errors.has_key?(:username)
  end

  test "empty mobile validation error" do
    a = _init_account()
    a.mobile_prefix = ''
    a.mobile_suffix = ''
    assert !a.valid?
    assert a.errors.length <= 2
    assert a.errors.has_key?(:mobile_prefix)
    assert a.errors.has_key?(:mobile_suffix)
    # same with nil
    a.mobile_prefix = nil
    a.mobile_suffix = nil
    assert !a.valid?
    assert a.errors.length <= 2
    assert a.errors.has_key?(:mobile_prefix)
    assert a.errors.has_key?(:mobile_suffix)
  end

  test "empty password validation error" do
    a = Account.new(
      :given_name => 'Foo',
      :surname => 'Bar',
      :email => 'foo@bar.com',
      :username => 'foobar',
      :password => '',
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
    assert_nil a.password
    assert !a.valid?
    assert a.errors.length <= 1
    assert a.errors.has_key?(:password)
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

  test "duplicate mobile phones" do
    a = _init_account()
    a.save!

    a = Account.new(
      :given_name => 'Foo2',
      :surname => 'Bar2',
      :email => 'foo2@bar.com',
      :username => 'foobar2',
      :password => 'foobarpassword0',
      :mobile_prefix => '334',
      :mobile_suffix => '4352702',
      :verification_method => 'gestpay_credit_card',
      :birth_date => '1980-10-10',
      :address => 'Via dei Tizii 6',
      :city => 'Rome',
      :zip => '00185',
      :state => 'Italy',
      :eula_acceptance => true,
      :privacy_acceptance => true
    )
    assert a.valid?
    # ensure mobile phone related fields are cleaned up
    assert a.mobile_prefix == nil
    assert a.mobile_suffix == nil
    # double check with save!
    a.mobile_prefix = '334'
    a.mobile_suffix = '4352702'
    a.save!
    assert a.mobile_prefix == nil
    assert a.mobile_suffix == nil
  end

  test "duplicate?" do
    a = _init_account()
    a.save!

    a2 = _init_account()
    a2.valid?
    assert a2.duplicate?

    a2.username = 'new'
    a2.valid?
    assert a2.duplicate?

    a2.email = 'new@new.com'
    a2.valid?
    assert a2.duplicate?

    a2.mobile_suffix = '4352333'
    a2.valid?
    assert !a2.duplicate?

    a2.mobile_suffix = '4352702'
    a2.valid?
    assert a2.duplicate?
  end

  test "validate_mobile_phone always" do
    Configuration.set('social_login_ask_mobile_phone', 'always')
    a = _init_account()
    a.verification_method = 'social_network'
    a.mobile_prefix = ''
    a.mobile_suffix = ''
    a.verified = false
    assert a.valid?
    a.save!

    a.mobile_prefix = 'wrong'
    a.mobile_suffix = 'wrong'
    assert !a.valid?

    a.mobile_prefix = '355'
    a.mobile_suffix = '4253801'
    a.mobile_prefix_confirmation = '000'
    a.mobile_suffix_confirmation = '4253801'
    assert !a.valid?

    a.mobile_prefix_confirmation = '355'
    a.mobile_suffix_confirmation = '4253801'
    assert a.valid?
    Configuration.set('social_login_ask_mobile_phone', 'unverified')
  end

  test "validate_mobile_phone unverified" do
    Configuration.set('social_login_ask_mobile_phone', 'unverified')
    a = _init_account()
    a.verification_method = 'social_network'
    a.mobile_prefix = ''
    a.mobile_suffix = ''
    a.verified = false
    assert a.valid?
    a.save!

    a.mobile_prefix = 'wrong'
    a.mobile_suffix = 'wrong'
    assert !a.valid?

    a.mobile_prefix = '355'
    a.mobile_suffix = '4253801'
    a.mobile_prefix_confirmation = '000'
    a.mobile_suffix_confirmation = '4253801'
    assert !a.valid?

    a.mobile_prefix_confirmation = '355'
    a.mobile_suffix_confirmation = '4253801'
    assert a.valid?
    a.destroy
  end

  test "validate_mobile_phone never" do
    Configuration.set('social_login_ask_mobile_phone', 'never')
    a = _init_account()
    a.verification_method = 'social_network'
    a.mobile_prefix = ''
    a.mobile_suffix = ''
    a.verified = false
    assert a.valid?
    a.save!

    a.mobile_prefix = 'wrong'
    a.mobile_suffix = 'wrong'
    assert a.valid?

    a.mobile_prefix = '355'
    a.mobile_suffix = '4253801'
    a.mobile_prefix_confirmation = '000'
    a.mobile_suffix_confirmation = '4253801'
    assert a.valid?

    a.mobile_prefix_confirmation = '355'
    a.mobile_suffix_confirmation = '4253801'
    assert a.valid?
    Configuration.set('social_login_ask_mobile_phone', 'unverified')
  end

  test "authorization is destroyed" do
    Configuration.set('social_login_ask_mobile_phone', 'never')
    a = _init_account()
    a.verification_method = 'social_network'
    a.mobile_prefix = ''
    a.mobile_suffix = ''
    a.verified = false
    assert a.valid?
    a.save!

    # crete associated authorization object
    assert_equal 0, SocialAuth.count
    SocialAuth.create(
      :provider => 'facebook',
      :uid => '10204334257594466',
      :user_id => a.id
    )
    assert_equal 1, SocialAuth.count

    # destroy account and ensure authorization has been destroyed
    a.destroy
    assert_equal 0, SocialAuth.count
    Configuration.set('social_login_ask_mobile_phone', 'unverified')
  end
end
