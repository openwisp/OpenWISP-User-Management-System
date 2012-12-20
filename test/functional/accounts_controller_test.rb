require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  test "should open verify_gestpay without login" do
    get :verify_gestpay
    assert_response :success
  end
  
  test "gestpay_success should redirect to login" do
    get :gestpay_success
    assert_response :redirect
  end
  
  test "gestpay_error should redirect to login" do
    get :gestpay_error
    assert_response :redirect
  end
end
