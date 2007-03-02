# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency "login_system"

class ApplicationController < ActionController::Base
  include LoginSystem

  before_filter :login_from_cookie, :set_current_user_on_model
  	
  def current_user
    if session[:user] && session[:user].instance_of?( User ) then
      return session[:user]
    else
      return nil
    end
  end
  
  def set_current_user_on_model
    User.current_user = current_user
  end

  # if user is not logged in but user has a login token cookie, check
  # if login token hasn't expired and log the user in
  def login_from_cookie
    if current_user.nil? && cookies[:login]
      if (user = User.find_by_login_token(cookies[:login])) && 
          user.login_token_created_at > 14.days.ago
        # reset the token (shorter lifetimes = more secure) & reset the timer
        user.set_login_token
        cookies[:login] = {:value => user.login_token, 
          :expires => 14.days.from_now}
        session[:user] = user
      end
    end
  end

end
