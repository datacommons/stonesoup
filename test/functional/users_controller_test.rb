require 'test_helper'

class UsersControllerTest < ActionController::TestCase

  test "successful login" do
    admin = users(:admin)
    post :login, :login => true, :user_login => 'admin', :user_password => 'password'
    #puts @response.body
    #puts session.to_json
    assert_redirected_to :action => 'index'
    assert_equal admin.id, session[:user].id
  end

  test "failed login" do
    admin = users(:admin)
    post :login, :login => true, :user_login => 'admin', :user_password => 'not-the-right-password'
    assert_template 'login'
    assert_nil session[:user]
  end

end
