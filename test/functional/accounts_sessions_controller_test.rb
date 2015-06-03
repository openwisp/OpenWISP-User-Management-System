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

  test "login ok" do
    post :create, :account_session => {
      :username => 'user1',
      :password => 'user1'
    }
    assert_redirected_to account_path
  end

  test "social login blank password fails" do
    a = Account.find_by_username('user1')
    a.verification_method = 'social_login'
    a.crypted_password = ''
    a.save!

    post :create, :account_session => {
      :username => 'socialuser',
      :password => ''
    }

    assert_select '#errorExplanation'
  end
end
