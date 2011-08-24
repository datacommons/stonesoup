require 'test_helper'

class SectorsControllerTest < DirectoryTestCase
  test_admin "should get index" do
    get :index
    assert_response :success unless blocked
    assert_not_nil assigns(:sectors) unless blocked
  end

  test_admin "should get new" do
    get :new
    assert_response :success unless blocked
  end

  test_admin "should create sector" do
    assert_difference('Sector.count') do
      post :create, :sector => { }
    end

    assert_redirected_to sector_path(assigns(:sector)) unless blocked
  end

  test_admin "should show sector" do
    get :show, :id => sectors(:one).id
    assert_response :success unless blocked
  end

  test_admin "should get edit" do
    get :edit, :id => sectors(:one).id
    assert_response :success unless blocked
  end

  test_admin "should update sector" do
    put :update, { :id => sectors(:one).id, :sector => { } }
    assert_redirected_to sector_path(assigns(:sector)) unless blocked
  end

  test_admin "should destroy sector" do
    assert_difference('Sector.count', -1) do
      delete :destroy, { :id => sectors(:one).id }
    end
    assert_redirected_to sectors_path unless blocked
  end
end
