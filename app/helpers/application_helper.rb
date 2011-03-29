# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def date_format_long(date)
    return '' if date.nil?
    return date.strftime('%B %d, %Y') # "July 20, 2009"
  end

  def date_format_short(date)
    return '' if date.nil?
    return date.strftime("%Y-%m-%d") # "2009-07-20"
  end
  
  def datetime_format_long(datetime)
    return '' if datetime.nil?
    return datetime.strftime("%b %d, %Y %I:%M %p") # "Jul 20, 2009 06:40 PM"
  end
  
  def datetime_format_short(datetime)
    return '' if datetime.nil?
    return datetime.strftime("%Y-%m-%d %I:%M %p") # "2009-07-20 06:37 PM"
  end
  
  def show_link(obj)
    return '' if obj.nil?
    if obj.respond_to?('link_name') and obj.respond_to?('link_hash')
      if obj.link_hash.nil?
        return obj.link_name
      else
        return link_to(obj.link_name, obj.link_hash)
      end
    else
      return ''
    end
  end

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

  def make_pointer(loc)
    # location latitude and longitude not always geocoded currently
    if (loc.latitude.nil? or loc.longitude.nil?)
      loc.save_ll
      loc.save(false)
    end
    if not (loc.latitude.nil? or loc.longitude.nil?)
      pt = [Float(loc.latitude),Float(loc.longitude)]    
      return pt
    else
      return nil
    end
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

  def core_zip_code(code)
    return code.gsub(/-.*/,'')
  end
end
