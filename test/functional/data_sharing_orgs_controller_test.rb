require 'test_helper'

class DataSharingOrgsControllerTest < DirectoryTestCase
  test_admin "should get index" do
    get :index
    assert_response :success unless blocked
    assert_not_nil assigns(:data_sharing_orgs) unless blocked
  end

  test_admin "should get new" do
    get :new
    assert_response :success unless blocked
  end

  test_admin "should create data_sharing_org" do
    assert_difference('DataSharingOrg.count') do
      post :create, :data_sharing_org => { }
    end

    assert_redirected_to data_sharing_org_path(assigns(:data_sharing_org)) unless blocked
  end

  test_admin "should show data_sharing_org" do
    get :show, :id => data_sharing_orgs(:one).id
    assert_response :success unless blocked
  end

  test_admin "should get edit" do
    get :edit, :id => data_sharing_orgs(:one).id
    assert_response :success unless blocked
  end

  test_admin "should update data_sharing_org" do
    put :update, :id => data_sharing_orgs(:one).id, :data_sharing_org => { }
    assert_redirected_to data_sharing_org_path(assigns(:data_sharing_org)) unless blocked
  end

  test_admin "should destroy data_sharing_org" do
    assert_difference('DataSharingOrg.count', -1) do
      delete :destroy, :id => data_sharing_orgs(:one).id
    end

    assert_redirected_to data_sharing_orgs_path unless blocked
  end
end
