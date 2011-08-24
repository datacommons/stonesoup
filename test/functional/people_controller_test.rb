require 'test_helper'

class PeopleControllerTest < DirectoryTestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:people)
  end

  test_admin "should get new" do
    get :new, {}
    assert_response :success unless blocked
  end

  test_admin "should create person" do
    assert_difference('Person.count') do
      post :create, :person => { :firstname => "Zig", :lastname => "de Lig" }, :access_rule => { :access_type => "PUBLIC" }
    end

    assert_redirected_to person_path(assigns(:person)) unless blocked
  end

  test_one_two "should show person" do
    get :show, :id => people(:one).id
    assert_response :success unless blocked
  end

  test_one_two "should get edit" do
    get :edit, :id => people(:one).id
    assert_response :success unless blocked
  end

  test_one_two "should update person" do
    put :update, :id => people(:one).id, :person => { }
    assert_redirected_to person_path(assigns(:person)) unless blocked
  end

  test_one_two "should destroy person" do
    assert_difference('Person.count', -1) do
      delete :destroy, :id => people(:one).id
    end

    assert_redirected_to people_path unless blocked
  end
end
