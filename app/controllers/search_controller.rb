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
    query = params[:q].to_s
    @latest_changes = get_latest_changes()
    
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
        query = '*' if query.blank? # give it something to force the query, even if the actual "search terms" are blank
        # process advanced params...
        unless params[:org_type_id].blank?
          org_type = OrgType.find_by_id(params[:org_type_id])
          query << " org_type:'#{org_type.name}'" unless org_type.nil?
        end
        unless params[:sector_id].blank?
          sector = Sector.find_by_id(params[:sector_id])
          query << " sector:'#{sector.name}'" unless sector.nil?
        end
        unless params[:county].blank?
          query << " county:'#{params[:county]}'"
        end
        unless params[:state].blank?
          query << " state:'#{params[:state]}'"
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
        logger.debug("After adding advanced search terms, query is: #{query}")
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
      @entries = ActsAsFerret::find(query,
                                    record_types,
                                    { 
                                      :page => params[:page], 
                                      :per_page => 15,
                                    },
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
      # TODO: find a better way to apply session filters
      unless session[:filters].nil?
        logger.debug("applying session filters to search results: #{session[:filters].inspect}")
        @entries.each do |e|
          logger.debug("############## a: #{e.class}")
          next unless e.is_a?(Organization) # only Orgs have Locations
          session[:filters].each do |k,v|
            if k == 'locations.physical_state'
              logger.debug("############## b")
              matches = false
              e.locations.each do |location|
                logger.debug("############## c")
                if session[:filters]['locations.physical_state'].collect{|a| a.downcase}.include?(location.physical_state.downcase)
                  logger.debug("############## d")
                  matches = true
                end
              end
              @entries.delete(e) unless matches
            else
              raise "Unknown session filter: [#{k}=#{v}]"
            end
          end
        end
      end
      
      f = params[:format]
      respond_to do |f| 
        f.html
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
      end
    end
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
    @entries = Location.find(:all, :origin => @origin, :within=>within, :order=>'distance asc', :units=>:miles)
    @entries = AccessRule.cleanse(@entries, current_user)
    @within = within
    
    @latest_changes = get_latest_changes()

    f = params[:format]
    respond_to do |f| 
      f.html
      f.xml { render :xml => @entries }
      f.csv do
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
    data = Organization.latest_changes(session[:filters]) + Person.latest_changes(session[:filters])
    logger.debug("data=#{data}")
    data = AccessRule.cleanse(data, current_user).sort{|a,b| b.updated_at <=> a.updated_at}[0..14]
    logger.debug("returning data=#{data}")
    return data
  end

end
