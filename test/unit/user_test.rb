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
end
