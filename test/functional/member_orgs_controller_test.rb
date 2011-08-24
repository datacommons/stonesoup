require 'test_helper'

class MemberOrgsControllerTest < DirectoryTestCase
  test_admin "should get index" do
    get :index
    assert_response :success unless blocked
    assert_not_nil assigns(:member_orgs) unless blocked
  end

  test_admin "should get new" do
    get :new
    assert_response :success unless blocked
  end

  test_admin "should create member_org" do
    assert_difference('MemberOrg.count') do
      post :create, :member_org => { }
    end

    assert_redirected_to member_org_path(assigns(:member_org)) unless blocked
  end

  test_admin "should show member_org" do
    get :show, :id => member_orgs(:one).id
    assert_response :success unless blocked
  end

  test_admin "should get edit" do
    get :edit, :id => member_orgs(:one).id
    assert_response :success unless blocked
  end

  test_admin "should update member_org" do
    put :update, :id => member_orgs(:one).id, :member_org => { }
    assert_redirected_to member_org_path(assigns(:member_org)) unless blocked
  end

  test_admin "should destroy member_org" do
    assert_difference('MemberOrg.count', -1) do
      delete :destroy, :id => member_orgs(:one).id
    end

    assert_redirected_to member_orgs_path unless blocked
  end
end
