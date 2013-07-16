require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  
  setup :activate_authlogic
  
  test "account registration should be accessible" do
    get :new
    assert_response :success
  end
  
  test "account page restricted to logged in users" do
    # unauthenticated user will be redirected to login
    get :show
    assert_redirected_to new_account_session_path
    # authenticated user should succeed
    # can't manage to get this to work...
    #AccountSession.create(users(:one))
    #get :show
    #puts response
    #assert_redirected_to account_path
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
  
  test "is_expired false" do
    AccountSession.create(users(:one))
    get :is_expired
    assert_response :success
    assert_equal false, JSON::parse(response.body)['is_expired']
  end
  
  test "is_expired true" do
    get :is_expired
    assert_response :success
    assert_equal true, JSON::parse(response.body)['is_expired']
  end
end
