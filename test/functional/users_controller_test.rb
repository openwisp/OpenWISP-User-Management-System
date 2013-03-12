require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, :user => {
        :given_name => 'Foo',
        :surname => 'Bar',
        :email => 'foo@bar.com',
        :username => 'foobar',
        :password => 'foobarpassword0',
        :mobile_prefix => '334',
        :mobile_suffix => '4352702',
        :verification_method => 'mobile_phone',
        :birth_date => '1980-10-10',
        :address => 'Via dei Tizii 6',
        :city => 'Rome',
        :zip => '00185',
        :state => 'Italy',
        :eula_acceptance => true,
        :privacy_acceptance => true
      }
    end

    assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, :id => users(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => users(:one).to_param
    assert_response :success
  end

  test "should update user" do
    put :update, :id => users(:one).to_param, :user => { }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, :id => users(:one).to_param
    end

    assert_redirected_to users_path
  end
end
