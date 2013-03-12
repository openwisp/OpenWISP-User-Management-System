require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  test "account registration should be accessible" do
    get :new
    assert_response :success
  end
  
  test "gestpay_verify_credit_card should redirect to login" do
    post :gestpay_verify_credit_card
    assert_redirected_to new_account_session_path
  end
  
  test "gestpay_verified_by_visa should redirect to login" do
    post :gestpay_verified_by_visa
    assert_redirected_to new_account_session_path
  end
  
  test "captive_portal_api" do
    account = Account.last()
    
    CONFIG['automatic_captive_portal_login'] = true
    # if disabled 
    if CONFIG['automatic_captive_portal_login'] == false
      # method should simply return false
      assert !account.captive_portal_login!
    #else
    #  # method should not raise an exception otherwise it means there's a misconfiguration issue
    #  account.captive_portal_login!
    end
  end
end
