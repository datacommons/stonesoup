class SearchController < ApplicationController
  def index
    search
    if params[:q]
      render :action => 'search'
    else
      render :action => 'welcome'
    end
  end

  def search
    @query = params[:q].to_s + ''
    @search_text = @query
    search_query = params[:q].to_s + '' # apparently the (+ '') is needed to make these distinct variables
    @latest_changes = get_latest_changes()

    if search_query == ""
      search_query = @site.blank_search
    end
    
    if params[:q]
      record_types = [Organization, Person]
      params[:page] = 1 unless params[:page]

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
      if params[:advanced] == '1'
        # process advanced params...
        unless params[:verified].blank?
          search_query << ' verified:yes' if params[:verified]
        end
        unless params[:org_type_id].blank?
          org_type = OrgType.find_by_id(params[:org_type_id])
          search_query << " org_type:'#{org_type.name}'" unless org_type.nil?
        end
        unless params[:sector_id].blank?
          sector = Sector.find_by_id(params[:sector_id])
          newterm = "sector:'#{sector.name}'"
          search_query << ' ' + newterm unless sector.nil? or search_query.include?(newterm)
        end
        unless params[:county].blank?
          newterm = "county:'#{params[:county]}'"
          search_query << ' ' + newterm unless search_query.include?(newterm)
        end
        unless params[:state].blank?
          newterm = "state:'#{params[:state]}'"
          search_query << ' ' + newterm unless search_query.include?(newterm)
        end
        unless params[:within].blank? or params[:origin].blank?
          record_types.delete(Person) # doesn't makes sense since Person records have no location
          within = params[:within].to_f
          if (within-within.to_i).abs<0.001
            within = within.to_i
          end
          origin = params[:origin]
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

      if not(params[:unrestricted])
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
        :page => params[:page], 
        :per_page => 15,
      }
      if params[:format]=='xml' or params[:format]=='csv' or params[:format]=='pdf' or defined? @unlimited_search
        # When providing xml or csv, there should be no
        # effective limit on the download size.  However,
        # depending on server load, we might want to 
        # restrict this to logged in users?
        pagination = { }
      end
      
      @entries = ActsAsFerret::find(filtered_query,
                                    record_types,
                                    pagination,
                                    { 
                                      :limit => :all,
                                      :conditions => flatSQL,
                                      :include => [:access_rule,
                                                   :users]
                                    })
=begin
      # filter results by proximity filter, if specified
      unless close_organization_ids.nil?
        @entries.reject! do |entry|
          return false if entry.is_a?(Organization) and !close_organization_ids.include?(entry.id)
          return true
        end
      end
=end

      f = params[:format]
      respond_to do |f| 
        f.html { if params['Map'] then render :action => 'map' else render end }
        f.xml { render :xml => @entries }
        f.csv do
          data = [@entries].flatten
          data = data.map {|r| r.reportable_data}.flatten
          cols = Organization.column_names
          table = Ruport::Data::Table.new(:data => data,
                                          :column_names => cols)
          send_data table.to_csv,
          :type => 'text/csv; charset=iso-8859-1; header=present',
          :disposition => ("attachment; filename=search.csv")
        end
        f.pdf do
          report = SearchReport.new(:data => @entries, :search => @search_text)
          send_data report.to_pdf, :filename => "search.pdf",
          :type => "application/pdf",
          :disposition => 'inline'
        end
        f.json { render :json => @entries }
      end
    end
  end

  def map
    @unlimited_search = true
    search
  end

  def near
    within = 10
    if params[:within]
      within = params[:within].to_f
      if (within-within.to_i).abs<0.001
        within = within.to_i
      end
    end
    @organization = Organization.find(params[:id])
    # for the moment, only look in the environs of one location
    @origin = @organization.locations[0]

    # search results need to be specific locations, otherwise could end up
    # with "nearby" results in another state
    # @entries = Location.find(:all, :origin => @origin, :within=>within, :order=>'distance asc', :units=>:miles).map {|l| l.organization}.uniq

    @locations = Location.find(:all, :origin => @origin, :within=>within, :order=>'distance asc', :units=>:miles)

    @locations = AccessRule.cleanse(@locations, current_user)
    @within = within
    
    @latest_changes = get_latest_changes()

    f = params[:format]
    respond_to do |f| 
      f.html
      f.xml { 
        # To do: generate good XML for locations.  For now, give organizations
        @entries = @locations.map {|l| l.organization}.uniq
        render :xml => @entries 
      }
      f.csv do
        # To do: generate good CSV for locations.  For now, give organizations
        @entries = @locations.map {|l| l.organization}.uniq
        data = [@entries].flatten
        data = data.map {|r| r.reportable_data}.flatten
        cols = Organization.column_names
        table = Ruport::Data::Table.new(:data => data,
                                        :column_names => cols)
        send_data(table.to_csv, 
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => ("attachment; filename=search.csv"))
      end
    end
  end

  def recent
    @entries = get_latest_changes
    render :layout => false
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
  end
  
  def render_js
#    render :file => 'main/render_js', :use_full_path => true
    #<%= render :file => 'rendered_includes/' + params[:src] + '.rhtml' %>
    render :file => 'rendered_includes/' + params[:src] + '.rhtml'
  end
  
protected
  def get_latest_changes
    data = Organization.latest_changes(session[:state_filter],session[:city_filter],session[:zip_filter],session[:dso_filter],session[:org_type_filter])
    if @site.should_show_latest_people
      data = data + Person.latest_changes(session[:state_filter])
    end
    logger.debug("data=#{data}")
    data = AccessRule.cleanse(data, current_user).sort{|a,b| ( a.updated_at and b.updated_at ) ? b.updated_at <=> a.updated_at : ( b.updated_at ? 1 : -1 )}
    if data.length>15
      data = data[0..14]
    end
    logger.debug("returning data=#{data}")
    return data
  end
end
