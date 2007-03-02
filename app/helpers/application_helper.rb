# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def current_user
    if session[:user] && session[:user].instance_of?( User ) then
      return session[:user]
    else
      return nil
    end
  end
end
