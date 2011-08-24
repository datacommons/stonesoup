require 'test_helper'

class LocationsControllerTest < DirectoryTestCase
  test_admin "should get index" do
    get :index
    assert_response :success unless blocked
    assert_not_nil assigns(:locations) unless blocked
  end

  test_admin "should get new" do
    get :new
    assert_response :success unless blocked
  end

  test_admin "should create location" do
    assert_difference('Location.count') do
      post :create, :location => { :physical_country => "US", :physical_city => "Boston" }, :id => 1
    end

    assert_redirected_to location_path(assigns(:location)) unless blocked
  end

  test_admin "should show location" do
    get :show, :id => locations(:one).id
    assert_response :success unless blocked
  end

  test_admin "should get edit" do
    get :edit, :id => locations(:one).id
    assert_response :success unless blocked
  end

  test_admin "should update location" do
    put :update, :id => locations(:one).id, :location => { }
    assert_redirected_to location_path(assigns(:location)) unless blocked
  end

  test_admin "should destroy location" do
    assert_difference('Location.count', -1) do
      delete :destroy, :id => locations(:one).id
    end

    assert_redirected_to locations_path unless blocked
  end
end
