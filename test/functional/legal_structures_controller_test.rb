require 'test_helper'

class LegalStructuresControllerTest < DirectoryTestCase
  test_admin "should get index" do
    get :index
    assert_response :success unless blocked
    assert_not_nil assigns(:legal_structures) unless blocked
  end

  test_admin "should get new" do
    get :new
    assert_response :success unless blocked
  end

  test_admin "should create legal_structure" do
    assert_difference('LegalStructure.count') do
      post :create, :legal_structure => { :name => "SPECIAL" }
    end

    assert_redirected_to legal_structures_path unless blocked
  end

  test_admin "should get edit" do
    get :edit, :id => legal_structures(:one).id
    assert_response :success unless blocked
  end

  test_admin "should update legal_structure" do
    put :update, :id => legal_structures(:one).id, :legal_structure => { }
    assert_redirected_to legal_structures_path unless blocked
  end

  test_admin "should destroy legal_structure" do
    assert_difference('LegalStructure.count', -1) do
      delete :destroy, :id => legal_structures(:one).id
    end

    assert_redirected_to legal_structures_path unless blocked
  end
end
