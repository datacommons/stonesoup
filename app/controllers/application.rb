# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency "login_system"

class ApplicationController < ActionController::Base
  include LoginSystem

  before_filter :login_from_cookie, :set_current_user_on_model, :set_custom_filters
  
  layout :custom_layout
  
private

  def get_site
    # These variables customize the layout

    @site_searches = ['"Northeast Biodiesel"','Connecticut','cooperative','zip:02139','sector:consumer', 'sector:nonprofit AND state:massachusetts', 'tech*', 'sector:food AND (organic OR local)','sector:food -organic','Noemi Giszpenc']
    @site_layout = :default
    # showing recently modified people is optional, since it is hard to
    # filter geographically right now
    @site_show_latest_people = true

    if ['ca.find.coop', 'california.find.coop', 'testca.find.coop'].include?(request.host)
      Email.website_base_url = 'http://california.find.coop'
      @site_layout = :california
    elsif ['me.find.coop','maine.find.coop','testme.find.coop'].include?(request.host)
      Email.website_base_url = 'http://maine.find.coop'
      @site_searches = ['food','local sprouts','zip:04412','*']
      @site_layout = :maine
      @site_show_latest_people = false
    elsif ['oh.find.coop','ohio.find.coop','testoh.find.coop'].include?(request.host)
      Email.website_base_url = 'http://ohio.find.coop'
      @site_searches = ['grocery','zip:43202','*']
      @site_layout = :ohio
      @site_show_latest_people = false
    else
      Email.website_base_url = 'http://find.coop'
    end
    return @site_layout
  end

  def custom_layout
    #return appropriate layout depending on value of request.host (domain name)
    # you can also do other dependent filtering, setting session variables, etc.
    site = get_site
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
    when :ohio
      session[:state_filter] = ['OH', 'Ohio']
    else
      session[:state_filter] = nil
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
