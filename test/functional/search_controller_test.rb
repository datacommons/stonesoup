require 'test_helper'

class SearchControllerTest < DirectoryTestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  # The following tests require a ferret server in test environment running

  test "find by exact title" do 
    get :search, :q => "HungryCoop"
    assert_select "div.listing", 1
  end

  test "use prefix" do 
    get :search, :q => "HungryC*"
    assert_select "div.listing", 1
  end

  test "use postfix" do 
    get :search, :q => "*Coop"
    assert_select "div.listing", 2
  end

  test "fail to find nonexistent org" do 
    get :search, :q => "VeryHungryCoop"
    assert_select "div.listing", 0
  end

end
