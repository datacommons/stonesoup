# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def current_user
    if session[:user] && session[:user].instance_of?( User ) then
      return session[:user]
    else
      return nil
    end
  end

  def default_map_type
    return :openlayers
  end

  def current_map_type
    if params['map'] then
      v = :openlayers
      case params['map']
        when 'google': v = :google
        when 'openstreetmap': v = :openstreetmap
        when 'openlayers': v = :openlayers
        when 'yahoo': v = :yahoo
      end
      session[:map] = v
      return v
    elsif session[:map] then
      return session[:map]
    else
      return default_map_type
    end
  end

end
