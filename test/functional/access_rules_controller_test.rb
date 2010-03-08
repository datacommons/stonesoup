require 'test_helper'

class AccessRulesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:access_rules)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create access_rule" do
    assert_difference('AccessRule.count') do
      post :create, :access_rule => { }
    end

    assert_redirected_to access_rule_path(assigns(:access_rule))
  end

  test "should show access_rule" do
    get :show, :id => access_rules(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => access_rules(:one).id
    assert_response :success
  end

  test "should update access_rule" do
    put :update, :id => access_rules(:one).id, :access_rule => { }
    assert_redirected_to access_rule_path(assigns(:access_rule))
  end

  test "should destroy access_rule" do
    assert_difference('AccessRule.count', -1) do
      delete :destroy, :id => access_rules(:one).id
    end

    assert_redirected_to access_rules_path
  end
end
