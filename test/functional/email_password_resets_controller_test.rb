require 'test_helper'

class EmailPasswordResetsControllerTest < ActionController::TestCase
  
  setup :activate_authlogic
  
  test "email password reset bug mobile" do
    get :edit, :id => '1gRJn1UcydddNjj6Im4y'
    assert_response :redirect
    
    mobile_agent = "Mozilla/5.0 (Linux; Android 4.1.1; Nexus 7 Build/JRO03D) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.166  Safari/535.19"
    @request.env["HTTP_USER_AGENT"] = mobile_agent
    get :edit, :id => '1gRJn1UcydddNjj6Im4y' 
    assert_response :redirect
  end
end
