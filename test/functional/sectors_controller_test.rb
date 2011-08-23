require 'test_helper'

class SectorsControllerTest < ActionController::TestCase
  def good_user
    { :user => users(:admin) }
  end

  def bad_user
    { :user => users(:normal) }
  end

  test "should get index" do
    get :index, {}, good_user
    assert_response :success
    assert_not_nil assigns(:sectors)
  end

  test "should fail to get index" do
    get :index, {}, bad_user
    assert_redirected_to :action => 'login'
  end

  test "should get new" do
    get :new, {}, good_user
    assert_response :success
  end

  test "should create sector" do
    assert_difference('Sector.count') do
      post :create, { :sector => { } }, good_user
    end

    assert_redirected_to sector_path(assigns(:sector))
  end

  test "should show sector" do
    get :show, { :id => sectors(:one).id }, good_user
    assert_response :success
  end

  test "should get edit" do
    get :edit, { :id => sectors(:one).id }, good_user
    assert_response :success
  end

  test "should update sector" do
    put :update, { :id => sectors(:one).id, :sector => { } }, good_user
    assert_redirected_to sector_path(assigns(:sector))
  end

  test "should destroy sector" do
    assert_difference('Sector.count', -1) do
      delete :destroy, { :id => sectors(:one).id }, good_user
    end

    assert_redirected_to sectors_path
  end
end
