require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "unverified" do
    assert_equal 0, User.unverified.length
    
    u = User.find(2)
    u.verified = false
    u.verified_at = nil
    u.save!
    
    assert_equal 1, User.unverified.length
    
    u = User.find(1)
    u.verified = false
    u.verified_at = nil
    u.save!
    
    assert_equal 2, User.unverified.length
  end
  
  test "unverified_destroyable" do
    assert_equal 0, User.unverified_destroyable.length
    
    u = User.find(1)
    u.verified = false
    u.verified_at = nil
    u.save!
    assert_equal 1, User.unverified_destroyable.length
    
    # credit card user doesn't count
    u = User.find(2)
    u.verified = false
    u.verified_at = nil
    u.save!
    assert_equal 1, User.unverified_destroyable.length
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
    assert_equal 0, User.disabled_destroyable.length
    
    u = User.find(1)
    u.verified = false
    u.save!
    assert_equal 1, User.disabled_destroyable.length
    
    # credit card user doesn't count
    u = User.find(2)
    u.save!
    assert_equal 1, User.disabled_destroyable.length
  end
end
