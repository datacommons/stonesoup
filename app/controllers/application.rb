# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency "login_system"

class ApplicationController < ActionController::Base
  include LoginSystem

  before_filter :login_from_cookie, :set_current_user_on_model, :set_custom_filters
  
  layout :custom_layout
  
private
  def get_site
    logger.debug("Determining custom filters based on request.host[#{request.host}]")
    if ['ca.find.coop', 'california.find.coop', 'testca.find.coop'].include?(request.host)
      logger.debug("... using custom template for: california")
      # use custom template
      return :california
    elsif ['main.find.coop','find.coop'].include?(request.host)
      logger.debug("... using custom template for: find.coop")
      return :regina
    elsif ['me.find.coop','maine.find.coop','testme.find.coop'].include?(request.host)
      logger.debug("... using custom template for: cooperative maine")
      return :maine
    else
      return :default
    end
  end

  def custom_layout
    #return appropriate layout depending on value of request.host (domain name)
    # you can also do other dependent filtering, setting session variables, etc.
    site = get_site
    case site
    when :default
      # is this needed? preserved from existing code.
      session[:filters] = nil
    end
    return site.to_s
  end

public
  def set_custom_filters
    site = get_site
    case site
    when :california
      # set custom filters for CA
      session[:state_filter] = ['CA', 'California']
    when :maine
      session[:state_filter] = ['ME', 'Maine']
    else
      session[:filters] = nil
    end
  end

  def valid_password?(password, username)
    return false unless password.match(/[A-Z]/)
    return false unless password.match(/[a-z]/)
    return false unless password.match(/[0-9\?\!\@\#\$\%\^\&\*\(\)\[\]\{\}\=\+\-]/)
    return false if password.downcase == username.downcase
    return false if password.match(/password/i)
    return true
  end
  
  PASSWORD_LENGTH = 6
  PASSWORD_CHARS = 'abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ23456789'
  def random_password(username)
    password = ''
    while(!valid_password?(password, username))
      password = ''
      PASSWORD_LENGTH.times do
        password += PASSWORD_CHARS[rand(PASSWORD_CHARS.length), 1]
      end
    end
    return password
  end
  	
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
