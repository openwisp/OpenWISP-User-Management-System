require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  
  setup :activate_authlogic
  
  test "should get index" do
    OperatorSession.create(operators(:admin))
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end
  
  test "filters" do
    OperatorSession.create(operators(:admin))
    
    get :index
    assert_select "table#users tbody" do
      assert_select "tr", User.count
    end
    
    get :index, { :verification_method => 'mobile_phone' }
    assert_select "table#users tbody" do
      assert_select "tr", User.where(:verification_method => 'mobile_phone').count
    end
    
    get :index, { :verification_method => 'gestpay_credit_card' }
    assert_select "table#users tbody" do
      assert_select "tr", 1
    end
    
    get :index, { :enabled => 'true' }
    assert_select "table#users tbody" do
      assert_select "tr", 2
    end
    
    get :index, { :verified => 'true' }
    assert_select "table#users tbody" do
      assert_select "tr", 2
    end
    
    get :index, { :enabled => 'false' }
    assert_select "table#users tbody" do
      assert_select "tr", 0
    end
    
    get :index, { :verified => 'false' }
    assert_select "table#users tbody" do
      assert_select "tr", 0
    end
  end

  test "should get new" do
    OperatorSession.create(operators(:admin))
    get :new
    assert_response :success
  end

  test "should create user" do
    OperatorSession.create(operators(:admin))
    assert_difference('User.count') do
      post :create, :user => {
        :given_name => 'Foo',
        :surname => 'Bar',
        :email => 'foo@bar.com',
        :username => 'foobar',
        :password => 'foobarpassword0',
        :verification_method => 'no_identity_verification',
        :birth_date => '1980-10-10',
        :address => 'Via dei Tizii 6',
        :city => 'Rome',
        :zip => '00185',
        :state => 'Italy',
        :eula_acceptance => true,
        :privacy_acceptance => true
      }
    end
  
    assert_response :success
  end

  test "should show user" do
    OperatorSession.create(operators(:admin))
    get :show, :id => users(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    OperatorSession.create(operators(:admin))
    get :edit, :id => users(:one).to_param
    assert_response :success
  end

  test "should update user" do
    OperatorSession.create(operators(:admin))
    put :update, :id => users(:one).to_param, :user => { }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    OperatorSession.create(operators(:admin))
    assert_difference('User.count', -1) do
      delete :destroy, :id => users(:one).to_param
    end
  
    assert_redirected_to users_path
  end
  
  test "should unverify user" do
    OperatorSession.create(operators(:admin))
    
    user = users(:one)
    assert_equal true, user.verified
    
    put :update, :id => user.to_param, :user => { :verified => 0 }
    assert_redirected_to user_path(assigns(:user))
    
    user = User.find(user.id)
    assert_equal false, user.verified
  end
  
  test "should disable user" do
    OperatorSession.create(operators(:admin))
    
    user = users(:one)
    assert_equal true, user.active
    
    put :update, :id => user.to_param, :user => { :active => 0 }
    assert_redirected_to user_path(assigns(:user))
    
    user = User.find(user.id)
    assert_equal false, user.active
  end
end
