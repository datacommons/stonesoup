require 'test_helper'

class OrganizationsControllerTest < DirectoryTestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations)
  end

  test_logged_in "should get new" do
    get :new
    assert_response :success unless blocked
  end

  test_logged_in "should create organization" do
    assert_difference('Organization.count') do
      post :create, :organization => { :name => "Zig a Lig Enterprises" }
    end

    assert_redirected_to :action => "elaborate" unless blocked
    # organization_path(assigns(:organization)) unless blocked
  end

  test "should show organization" do
    get :show, :id => organizations(:one).id
    assert_response :success
  end

  test_logged_in "should get edit" do
    get :edit, :id => organizations(:one).id
    assert_response :success unless blocked
  end

  test_logged_in "should update organization" do
    put :update, :id => organizations(:one).id, :organization => { }
    assert_redirected_to organization_path(assigns(:organization)) unless blocked
  end

  test_logged_in "should destroy organization" do
    assert_difference('Organization.count', -1) do
      delete :destroy, :id => organizations(:one).id
    end

    assert_redirected_to organizations_path unless blocked
  end
end
