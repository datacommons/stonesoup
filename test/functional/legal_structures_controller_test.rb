require 'test_helper'

class LegalStructuresControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:legal_structures)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create legal_structure" do
    assert_difference('LegalStructure.count') do
      post :create, :legal_structure => { }
    end

    assert_redirected_to legal_structures_path
  end

  test "should get edit" do
    get :edit, :id => legal_structures(:one).id
    assert_response :success
  end

  test "should update legal_structure" do
    put :update, :id => legal_structures(:one).id, :legal_structure => { }
    assert_redirected_to legal_structures_path
  end

  test "should destroy legal_structure" do
    assert_difference('LegalStructure.count', -1) do
      delete :destroy, :id => legal_structures(:one).id
    end

    assert_redirected_to legal_structures_path
  end
end
