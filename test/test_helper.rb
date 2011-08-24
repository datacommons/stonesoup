ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  fixtures :all

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
end

def test_users(good, bad, name, &block)
  for test_user_good in good
    test "#{name}_#{test_user_good}" do
      @expect_good = true
      @current_test_session = session_for_user(test_user_good)
      instance_eval(&block)
      @current_test_session = {}
    end
  end
  for test_user_bad in bad
    test "#{name}_#{test_user_bad}" do
      @expect_good = false
      @current_test_session = session_for_user(test_user_bad)
      instance_eval(&block)
      begin
        assert_response :failed
      rescue
        begin
          assert_redirected_to '/'
        rescue
          #begin
          assert_redirected_to :action => 'login'
          #rescue
          #  puts @response.body
          #  raise
          #end
        end
      end
      @current_test_session = {}
      @expect_good = true
    end
  end
end

def test_admin(name, &block)
  test_users([:admin], [:normal, :anon], name, &block)
end

def test_logged_in(name, &block)
  test_users([:normal], [:anon], name, &block)
end

def test_one_two(name, &block)
  test_users([:one], [:two], name, &block)
end


class DirectoryTestCase < ActionController::TestCase
  def initialize(x)
    @expect_good = true
    super(x)
  end

  def session_for_user(name)
    if name == :anon
      {}
    else
      { :user => users(name) }
    end
  end

  def admin_user
    { :user => users(:admin) }
  end

  def normal_user
    { :user => users(:normal) }
  end

  def no_user
    { }
  end

  def blocked
    not(@expect_good)
  end

  def assert_difference(expressions, difference = 1, message = nil, &block)
    if not(blocked)
      super(expressions,difference,message,&block)
    else
      super(expressions,0,message,&block)
    end
  end

  def user_process(action, parameters = nil, session = nil, flash = nil, http_method = 'GET')
    # For Rails 2.2.2 ...
    @request.env['REQUEST_METHOD'] = http_method if defined?(@request)
    if session.nil?
      session = @current_test_session
    end
    process(action, parameters, session, flash)
  end

  def get(action, parameters = nil, session = nil, flash = nil)
    user_process(action, parameters, session, flash, "GET")
  end
  
  def post(action, parameters = nil, session = nil, flash = nil)
    user_process(action, parameters, session, flash, "POST")
  end
  
  def put(action, parameters = nil, session = nil, flash = nil)
    user_process(action, parameters, session, flash, "PUT")
  end
  
  def delete(action, parameters = nil, session = nil, flash = nil)
    user_process(action, parameters, session, flash, "DELETE")
  end

end
