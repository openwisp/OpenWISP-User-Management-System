require 'test_helper'

class PasswordResetsControllerTest < ActionController::TestCase
  
  setup :activate_authlogic
  
  test "password reset bug" do
    AccountSession.create(users(:one))
    get :new
    assert_response :success
  end
end
