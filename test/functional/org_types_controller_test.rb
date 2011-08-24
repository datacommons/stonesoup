require 'test_helper'

class OrgTypesControllerTest < DirectoryTestCase
  test_admin "should get index" do
    get :index
    assert_response :success unless blocked
    assert_not_nil assigns(:org_types) unless blocked
  end

  test_admin "should get new" do
    get :new
    assert_response :success unless blocked
  end

  test_admin "should create org_type" do
    assert_difference('OrgType.count') do
      post :create, :org_type => { }
    end

    assert_redirected_to org_type_path(assigns(:org_type)) unless blocked
  end

  test_admin "should show org_type" do
    get :show, :id => org_types(:one).id
    assert_response :success unless blocked
  end

  test_admin "should get edit" do
    get :edit, :id => org_types(:one).id
    assert_response :success unless blocked
  end

  test_admin "should update org_type" do
    put :update, :id => org_types(:one).id, :org_type => { }
    assert_redirected_to org_type_path(assigns(:org_type)) unless blocked
  end

  test_admin "should destroy org_type" do
    assert_difference('OrgType.count', -1) do
      delete :destroy, :id => org_types(:one).id
    end

    assert_redirected_to org_types_path unless blocked
  end
end
