require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "unverified" do
    assert_equal 0, User.unverified.count

    u = User.find(2)
    u.verified = false
    u.verified_at = nil
    u.save!

    assert_equal 1, User.unverified.count

    u = User.find(1)
    u.verified = false
    u.verified_at = nil
    u.save!

    assert_equal 2, User.unverified.count
  end

  test "unverified_destroyable" do
    assert_equal 0, User.unverified_destroyable.count

    u = User.find(1)
    u.verified = false
    u.verified_at = nil
    u.save!
    assert_equal 1, User.unverified_destroyable.count

    # credit card user doesn't count
    u = User.find(2)
    u.verified = false
    u.verified_at = nil
    u.save!
    assert_equal 1, User.unverified_destroyable.count
  end

  test "unverified_deactivable" do
    assert_equal 0, User.unverified_deactivable.count

    u = User.find(1)
    u.verified = false
    u.verified_at = nil
    u.save!
    assert_equal 0, User.unverified_deactivable.count

    # credit card user doesn't count
    u = User.find(2)
    u.verified = false
    u.verified_at = nil
    u.save!
    assert_equal 1, User.unverified_deactivable.count

    u = User.find(2)
    u.active = false
    u.save!
    assert_equal 0, User.unverified_deactivable.count
  end

  test "disabled" do
    assert_equal 0, User.disabled.length

    u = User.find(2)
    u.verified = false
    u.save!

    assert_equal 1, User.disabled.length

    u = User.find(1)
    u.verified = false
    u.save!

    assert_equal 2, User.disabled.length
  end

  test "disabled_destroyable" do
    assert_equal 0, User.disabled_destroyable.count

    u = User.find(1)
    u.verified = false
    u.save!
    assert_equal 1, User.disabled_destroyable.count

    # credit card user doesn't count
    u = User.find(2)
    u.verified = false
    u.save!
    assert_equal 1, User.disabled_destroyable.count
  end

  test "disabled_deactivable" do
    assert_equal 0, User.disabled_deactivable.count

    u = User.find(1)
    u.verified = false
    u.save!
    assert_equal 0, User.disabled_deactivable.count

    # credit card user doesn't count
    u = User.find(2)
    u.verified = false
    u.save!
    assert_equal 1, User.disabled_deactivable.count

    u = User.find(1)
    u.verified = true
    u.save!
    assert_equal 1, User.disabled_deactivable.count

    u = User.find(2)
    u.active = false
    u.save!
    assert_equal 0, User.disabled_deactivable.count
  end

  def _create_fake_users
    User.destroy_all
    (0..10).each do |i|
      account = Account.new(
        :given_name => "Foo #{i}",
        :surname => "Bar #{i}",
        :email => "foo#{i}@bar.com",
        :username => "foobar_#{i}",
        :password => "foobarpassword#{i}",
        :mobile_prefix => '334',
        :mobile_suffix => "435270#{i}",
        :verification_method => 'mobile_phone',
        :birth_date => '1980-10-10',
        :address => 'Via dei Tizii 6',
        :city => 'Rome',
        :zip => '00185',
        :state => 'Italy',
        :eula_acceptance => true,
        :privacy_acceptance => true
      )
      account.save!
      user = User.last
      user.verified = true
      user.verified_at = i.days.ago.change({:hour => 12})
      user.created_at = user.verified_at
      user.save!
    end
  end

  test "registered_exactly_on" do
    self._create_fake_users()

    (0..10).each do |i|
      assert_equal 1, User.registered_exactly_on(i.days.ago.to_date)
    end
  end

  test "registered_on" do
    self._create_fake_users()

    (0..10).each do |i|
      assert_equal 11-i, User.registered_on(i.days.ago.to_date)
    end
  end

  test "authorization is destroyed" do
    a = Account.new(
      :given_name => "Social",
      :surname => "Bar",
      :email => "foo-social@bar.com",
      :username => "foobar_social",
      :password => "foobarpassword1",
      :mobile_prefix => '334',
      :mobile_suffix => "4252800",
      :verification_method => 'social_network',
      :birth_date => '1980-10-10',
      :address => 'Via dei Tizii 6',
      :city => 'Rome',
      :zip => '00185',
      :state => 'Italy',
      :eula_acceptance => true,
      :privacy_acceptance => true
    )
    a.save!
    u = User.find(a.id)

    # crete associated authorization object
    assert_equal 0, SocialAuth.count
    SocialAuth.create(
      :provider => 'facebook',
      :uid => '10204334257594466',
      :user_id => u.id
    )
    assert_equal 1, SocialAuth.count

    # destroy account and ensure authorization has been destroyed
    u.destroy
    assert_equal 0, SocialAuth.count
  end
end
