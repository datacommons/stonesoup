# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency "login_system"

require 'sites'

class ApplicationController < ActionController::Base
  include LoginSystem

  before_filter :login_from_cookie, :set_current_user_on_model, :set_custom_filters
  
  layout :custom_layout
  
private

  def get_site
    site = Site.get_subsite(request.host)
    if site.nil?
      site = Site.get_subsite('find.coop') 
    end
    site
  end

  def custom_layout
    #return appropriate layout depending on value of request.host (domain name)
    # you can also do other dependent filtering, setting session variables, etc.
    Email.website_base_url = 'http://' + @site.canonical_name
    
    if params[:iframe]
      logger.debug("setting session's IFRAME status to: #{params[:iframe]}")
      session[:iframe] = (params[:iframe].to_i == 1)
    end
    return @site.layout.to_s + "/template"
  end

public
  def set_custom_filters
    @site = get_site
    session[:state_filter] = @site.state_filter
    session[:city_filter] = @site.city_filter
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
