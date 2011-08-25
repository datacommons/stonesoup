require 'test_helper'

class OrganizationsPeopleControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations_people)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create organizations_person" do
    assert_difference('OrganizationsPerson.count') do
      post :create, :organizations_person => { :person => people(:one), :organization => organizations(:one) }
    end

    assert_redirected_to organizations_person_path(assigns(:organizations_person))
  end

  test "should show organizations_person" do
    get :show, :id => organizations_people(:hungry_coop_man).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => organizations_people(:hungry_coop_man).id
    assert_response :success
  end

  test "should update organizations_person" do
    put :update, :id => organizations_people(:hungry_coop_man).id, :organizations_person => { }
    assert_redirected_to organizations_person_path(assigns(:organizations_person))
  end

  test "should destroy organizations_person" do
    assert_difference('OrganizationsPerson.count', -1) do
      delete :destroy, :id => organizations_people(:hungry_coop_man).id
    end

    assert_redirected_to organizations_people_path
  end
end
