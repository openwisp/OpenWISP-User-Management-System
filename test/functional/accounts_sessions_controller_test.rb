require 'test_helper'

class AccountSessionsControllerTest < ActionController::TestCase
  test "login page should be accessible" do
    get :new
    assert_response :success
  end
  
  test "logout page should be accessible to logged in users only" do
    get :destroy
    assert_redirected_to new_account_session_path
  end
end