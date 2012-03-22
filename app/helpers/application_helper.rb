# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def data_import_plugins
    dir = Dir.open IMPORT_PLUGINS_DIRECTORY
    plugin_names = []
    dir.entries.each do |entry|
      next unless entry.match(/.+\.rb$/)
      plugin_names.push entry.gsub(/\.rb$/,'')
    end
    plugin_names
  end
  
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

  def obscure_email(_email)
    return nil if _email.nil? #Don't bother if the parameter is nil.
    lower = ('a'..'z').to_a
    upper = ('A'..'Z').to_a
    _email.split('').map { |char|
      output = lower.index(char) + 97 if lower.include?(char)
      output = upper.index(char) + 65 if upper.include?(char)
      output ? "&##{output};" : (char == '@' ? '&#0064;' : char)
    }.join
  end

  def javascript_email(email)
    return nil if email.nil?
    if current_user.nil?
      user,domain = email.split('@')
      [
       "<script type=\"text/javascript\">document.write(['",
       obscure_email(user),
       "\',\'",
       obscure_email(domain),
       "'].join('&#64;'))</script>",
      ].join
    else
      obscure_email(email)
    end
  end

  def javascript_email_link(email)
    return nil if email.nil?
    user,domain = email.split('@')
    [
     "javascript:missive(['",
     obscure_email(user),
     "\',\'",
     obscure_email(domain),
     "'].join('&#64;'))",
    ].join
  end

  def get_trunk_id
    if @organization
      return @organization.id
    end
    nil
  end

  def get_branch_id
    if @organization2
      return @organization2.id
    end
    get_trunk_id
  end

  def truncate_string(s,len)
    return s if s.index(/[a-z]/i).nil?
    s = s[0,len-4].gsub(/[^ ]*$/,"")
    return s + " ..."
  end

  def search_core(_params)
    search_query = _params[:q].to_s + ''

    entries = []

    if _params[:q]
      record_types = [Organization, Person]
      _params[:page] = 1 unless _params[:page]

      conditionSQL = {}
      conditionParams = {}
      for t in [:organization,:person]
        conditionSQL[t] = []
        conditionParams[t] = []
      end
      
      if current_user
        basic_access_conditionSQL = "access_rules.access_type IN (\'#{AccessRule::ACCESS_TYPE_PUBLIC}\',\'#{AccessRule::ACCESS_TYPE_LOGGEDIN}\')"
        full_access_conditionSQL = "access_rules.access_type IN (\'#{AccessRule::ACCESS_TYPE_PUBLIC}\',\'#{AccessRule::ACCESS_TYPE_LOGGEDIN}\') OR organizations_users.user_id = ?"
        conditionSQL[:person] <<= basic_access_conditionSQL
        conditionSQL[:organization] <<= full_access_conditionSQL
        conditionParams[:organization] <<= current_user.id
      else
        access_conditionSQL = "access_rules.access_type = \'#{AccessRule::ACCESS_TYPE_PUBLIC}\'"
        conditionSQL[:person] <<= access_conditionSQL
        conditionSQL[:organization] <<= access_conditionSQL
      end
      
      proximity_conditionSQL = nil
      if _params[:advanced] == '1'
        # process advanced params...
        if search_query != ""
          search_query = "(#{search_query})"
        end

        unless _params[:verified].blank?
          search_query << ' verified:yes' if _params[:verified]
        end
        unless _params[:org_type_id].blank?
          org_type = OrgType.find_by_id(_params[:org_type_id])
          search_query << " +org_type:'#{org_type.name}'" unless org_type.nil?
        end
        unless _params[:sector_id].blank?
          sector = Sector.find_by_id(_params[:sector_id])
          newterm = "+sector:'#{sector.name}'"
          search_query << ' ' + newterm unless sector.nil? or search_query.include?(newterm)
        end
        unless _params[:county].blank?
          newterm = "+county:'#{_params[:county]}'"
          search_query << ' ' + newterm unless search_query.include?(newterm)
        end
        unless _params[:country].blank?
          newterm = "+country:'#{_params[:country]}'"
          search_query << ' ' + newterm unless search_query.include?(newterm)
        end
        unless _params[:state].blank?
          newterm = "+state:'#{_params[:state]}'"
          search_query << ' ' + newterm unless search_query.include?(newterm)
        end
        unless _params[:within].blank? or _params[:origin].blank?
          record_types.delete(Person) # doesn't makes sense since Person records have no location
          within = _params[:within].to_f
          if (within-within.to_i).abs<0.001
            within = within.to_i
          end
          origin = _params[:origin]
          #TODO: is there a better way to do this? tried implementing it as a conditionSQL "conditions.id IN ()" but that broke when doing the query on the People table since there is no organizations.id in that query
          locations = Location.find(:all, :origin => origin, :within=>within, :order=>'distance asc', :units=>:miles)
          close_organization_ids = locations.collect{|location| location.organization.id}.uniq
          proximity_conditionSQL = 'organizations.id IN ('+close_organization_ids.join(',')+')'
          logger.debug("close_organization_ids = #{close_organization_ids.inspect}")
        end
        search_query = '*' if search_query.blank? # give it something to force the query, even if the actual "search terms" are blank
        logger.debug("After adding advanced search terms, query is: #{search_query}")
      end
      
      unless proximity_conditionSQL.nil?
        conditionSQL[:organization] <<= proximity_conditionSQL
      end

      flatSQL = {}
      for t in conditionSQL.keys
        flatSQL[t] = [conditionSQL[t].collect{|sql| '('+sql+')'}.join(' AND ')]
        flatSQL[t] += conditionParams[t]
      end
      
      #condSQL = [access_conditionSQL, proximity_conditionSQL].compact.collect{|sql| '('+sql+')'}.join(' AND ')
      logger.debug("flat conditions: #{flatSQL.inspect}")
      filtered_query = search_query
      append_query = ""

      if not(_params[:unrestricted])
        unless session[:state_filter].blank?
          logger.debug("applying session state filters to search results: #{session[:state_filter].inspect}")
          addl_criteria = []
          [session[:state_filter]].flatten.each do |state|
            # Nested parentheses do not seem to work, omit for now.
            # could solve during indexing with a virtual field.
            #if state.length == 2  # abbreviation, make sure it's qualified with USA country:
            # addl_criteria << "(state:#{state} AND (country:'united states' OR country:usa))"
            #else
            #  addl_criteria << "state:'#{state}'"
            #end
            addl_criteria << "state:\"#{state}\""
          end
          append_query = "#{append_query} +(#{addl_criteria.join(' OR ')})"
          filtered_query = "+(#{search_query})#{append_query}"
          logger.debug("After adding state filter to query, query is: #{filtered_query}")
        end

        unless session[:city_filter].blank?
          logger.debug("applying city filters to search results: #{session[:city_filter].inspect}")
          addl_criteria = []
          [session[:city_filter]].flatten.each do |city|
            addl_criteria << "city:\"#{city}\""
          end
          append_query = "#{append_query} +(#{addl_criteria.join(' OR ')})"
          filtered_query = "+(#{search_query})#{append_query}"
          logger.debug("After adding city filter to query, query is: #{filtered_query}")
        end

        unless session[:zip_filter].blank?
          logger.debug("applying zip filters to search results: #{session[:zip_filter].inspect}")
          addl_criteria = []
          [session[:zip_filter]].flatten.each do |zip|
            addl_criteria << "zip:#{zip}"
          end
          append_query = "#{append_query} +(#{addl_criteria.join(' OR ')})"
          filtered_query = "+(#{search_query})#{append_query}"
          # filtered_query = "+(#{search_query}) +(#{addl_criteria.join(' OR ')})"
          logger.debug("After adding zip filter to query, query is: #{filtered_query}")
        end

        unless session[:dso_filter].blank?
          logger.debug("applying dso filters to search results: #{session[:dso_filter].inspect}")
          addl_criteria = []
          [session[:dso_filter]].flatten.each do |x|
            addl_criteria << "pool:\"#{x}\""
          end
          append_query = "#{append_query} +(#{addl_criteria.join(' OR ')})"
          filtered_query = "+(#{search_query})#{append_query}"
          # filtered_query = "+(#{search_query}) +(#{addl_criteria.join(' OR ')})"
          logger.debug("After adding dso filter to query, query is: #{filtered_query}")
        end

        unless session[:org_type_filter].blank?
          logger.debug("applying org_type filters to search results: #{session[:org_type_filter].inspect}")
          addl_criteria = []
          [session[:org_type_filter]].flatten.each do |x|
            addl_criteria << "org_type:\"#{x}\""
          end
          append_query = "#{append_query} +(#{addl_criteria.join(' OR ')})"
          filtered_query = "+(#{search_query})#{append_query}"
          # filtered_query = "+(#{search_query}) +(#{addl_criteria.join(' OR ')})"
          logger.debug("After adding org_type filter to query, query is: #{filtered_query}")
        end
      end

      pagination = { 
        :page => _params[:page], 
        :per_page => 15,
      }
      if _params[:format]=='xml' or _params[:format]=='csv' or _params[:format]=='pdf' or defined? @unlimited_search or _params['Map'] 
        # When providing xml or csv, there should be no
        # effective limit on the download size.  However,
        # depending on server load, we might want to 
        # restrict this to logged in users?
        pagination = { }
      end
      
      entries = ActsAsFerret::find(filtered_query,
                                   record_types,
                                   pagination,
                                   { 
                                     :limit => :all,
                                     :conditions => flatSQL,
                                     :include => [:access_rule,
                                                  :users]
                                   })
    end
    entries
  end

  def get_listing(query)
    p = {}
    p[:q] = query
    search_core(p)
  end

end
