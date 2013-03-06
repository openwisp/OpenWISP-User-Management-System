require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  test "gestpay_verify_credit_card should redirect to login" do
    post :gestpay_verify_credit_card
    assert_redirected_to '/account_session/new'
  end
  
  test "gestpay_verified_by_visa should redirect to login" do
    post :gestpay_verified_by_visa
    assert_redirected_to '/account_session/new'
  end
  
  #test "captive_portal_api" do
  #  account = Account.last()
  #  if CONFIG['automatic_captive_portal_login'] == false
  #    assert account.captive_portal_login!
  #  end
  #end
end
