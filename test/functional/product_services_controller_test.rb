require 'test_helper'

class ProductServicesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:product_services)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product_service" do
    assert_difference('ProductService.count') do
      post :create, :product_service => { }, :id => 1, :new_product_service => { :name => "Zigaliganol" }
    end

    assert_redirected_to product_service_path(assigns(:product_service))
  end

  test "should show product_service" do
    get :show, :id => product_services(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => product_services(:one).id
    assert_response :success
  end

  test "should update product_service" do
    put :update, :id => product_services(:one).id, :product_service => { }
    assert_redirected_to product_service_path(assigns(:product_service))
  end

  test "should destroy product_service" do
    assert_difference('ProductService.count', -1) do
      delete :destroy, :id => product_services(:one).id
    end

    assert_redirected_to product_services_path
  end
end
