class SearchItem
  def initialize(name,family,params)
    @name = name
    @family = family
    @params = params.delete_if{|x,y| y.nil?}
    if family == "City" || family == "Postal code"
      if @params[:state]
        @name = @name + ", #{@params[:state]}" if @params[:state].length >= 1
      end
    end
    if family == "City" || family == "State" || family == "Postal code"
      @name = @name + ", #{@params[:country]}" if @params[:country]
    end
    if family == "Postal code"
      # temporary: need to delete country if USA, since a lot of US data snuck in without country
      @params = @params.delete_if{|x,y| x == :city or x == :state or (x==:country and (y.downcase.include? "united states" or y=="USA" or y=="US"))}
    end
  end

  def name
    @name
  end
  
  def family
    @family
  end

  def id
    0
  end

  def to_param
    @params
  end
end

class SearchController < ApplicationController
  def index
    search
    if params[:q] || params[:act]
      render :action => 'search'
    else
      render :action => 'welcome'
    end
  end

  def search
    if not (params[:q]||params[:act])
      @latest_changes = get_latest_changes()
      return
    end

    params[:q] = "" unless params[:q]
    @query = params[:q].to_s + ''
    @search_text = @query
    search_query = params[:q].to_s + '' # apparently the (+ '') is needed to make these distinct variables

    _params = params.clone
    if search_query == "" and _params[:advanced] != '1' and not(params[:act])
      search_query = @site.blank_search
      _params[:q] = search_query
    end

    @entries = @template.search_core(_params)

    if params[:merge]
      @merge_active = true
      if params[:merge] == 'start'
        session[:merge] = nil
      end
      params[:merge] = true
      session[:merge_search] = params
    else
      @merge_active = false
    end
    @merge_target = session[:merge] 

    if params[:q]
      f = params[:format]
      respond_to do |f| 
        f.html { if params['Map'] then render :action => 'map' else render end }
        f.kml { render :file => 'search/search.kml.erb', :layout => false }
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
          report = SearchReport.new(:data => @entries, :search => @search_text,
                                    :user => current_user,
                                    :style => params[:style])
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


  def auto_complete_test
    render :action => 'auto_complete_test'
  end

  def auto_complete
    # geo = false
    # geo = (params[:geo].to_s == "true") if params[:geo]

    search = params[:search]
    search = "" if search.nil?
    name = search

    template = "name LIKE ?"
    value = (name.length>2 ? "%" : "")+name+"%"
    limit = 50
    useful_limit = 5
    
    tags = []
    organizations = []
    people = []
    locations = []
    areas = []

    if name.length>=1
      joinSQL, condSQLs, condParams = Organization.all_join(session)
      joinSQL = nil if condSQLs.empty?
      if joinSQL
        joinSQL = "INNER JOIN taggings ON taggings.tag_id = tags.id INNER JOIN organizations ON taggings.taggable_id = organizations.id #{joinSQL}"
        condSQLs.unshift("taggings.taggable_type = ?")
        condParams.unshift("Organization")
      end
      if name.length>2
        condSQLs << template.gsub("name","tags.name")
        condParams << value
      else
        condSQLs << "tags.name LIKE ? or tags.name LIKE ?"
        condParams << name + "%"
        condParams << " " + name + "%"
      end
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      tags = Tag.find(:all, :conditions => conditions, :joins => joinSQL, :limit => limit)
    end

    if name.length>=1
      joinSQL, condSQLs, condParams = Organization.all_join(session)
      joinSQL = nil if condSQLs.empty?
      condSQLs << template.gsub("name","organizations.name")
      condParams << value
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      organizations = Organization.find(:all, :conditions => conditions, :joins => joinSQL, :limit => limit*5)
    end

    if name.length>=2
      first, last = name.split(/ /)
      unless last.nil?
        last = nil if last == ""
      end
      joinSQL, condSQLs, condParams = Organization.all_join(session)
      joinSQL = "INNER JOIN organizations_people ON organizations_people.person_id = people.id INNER JOIN organizations ON organizations_people.organization_id = organizations.id #{joinSQL}"
      joinSQL = nil if condSQLs.empty?
      unless last.nil?
        condSQLs << "people.lastname LIKE ? AND people.firstname LIKE ?"
        condParams << (last + "%")
        condParams << (first + "%")
      else
        condSQLs << "people.lastname LIKE ? OR people.firstname LIKE ?"
        condParams << (first + "%")
        condParams << (first + "%")
      end
      # people = Person.find(:all, :conditions => ["lastname LIKE ? OR firstname LIKE ?",first + "%",first+"%"], :limit => limit)
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      people = Person.find(:all, :conditions => conditions, :joins => joinSQL, :limit => limit)
    end

    if name.length>=2
      ignore, locCondSQLs, locCondParams = Organization.location_join(session)
      joinSQL, condSQLs, condParams = Organization.tag_join(session)
      joinSQL = "INNER JOIN organizations ON organizations.id = locations.organization_id #{joinSQL}"
      condSQLs = condSQLs + locCondSQLs
      condParams = condParams + locCondParams
      joinSQL = nil if condSQLs.empty?
      condSQLs << "locations.physical_address1 LIKE ? OR locations.physical_city LIKE ?"
      condParams << value
      condParams << value
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      locations = Location.find(:all, :conditions => conditions, 
                                :joins => joinSQL,
                                :limit => limit)
      
    end

    if name.length>=1
      ignore, locCondSQLs, locCondParams = Organization.location_join(session)
      joinSQL, condSQLs, condParams = Organization.tag_join(session)
      joinSQL = "INNER JOIN organizations ON organizations.id = locations.organization_id #{joinSQL}"
      condSQLs = condSQLs + locCondSQLs
      condParams = condParams + locCondParams
      joinSQL = nil if condSQLs.empty?
      condSQLs << "locations.physical_city LIKE ? OR locations.physical_state LIKE ? OR locations.physical_country LIKE ? OR locations.physical_zip LIKE ?"
      condParams << value
      condParams << value
      condParams << value
      condParams << value
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      area_locations = Location.find(:all, :conditions => conditions, 
                                     :joins => joinSQL,
                                     :limit => limit)
      areas = area_locations.map{|x| areaize(x,name)}.compact.uniq
    end

    results = []

    groups = [tags, areas, organizations, people, locations]

    groups.each do |result_set|
      result_set.sort!{|a,b| diff(a.name,b.name,false,false,search)}
    end

    global_limit = 25

    if groups.flatten.length>global_limit
      organizations = self.whittle(organizations,name,useful_limit,limit)
      groups = [tags, areas, organizations, people, locations]
    end

    while groups.flatten.length>global_limit
      groups.each_with_index do |result_set,idx|
        if idx==0
          if result_set.length<global_limit*0.5
            next
          end
        end
        result_set.slice!((result_set.length*0.8).floor,result_set.length)
      end
      groups = [tags, areas, organizations, people, locations]
    end

    groups.each do |result_set|
      result_set.each do |h|
        target = h
        is_tag = false
        if h.respond_to? "effective_root"
          is_tag = true
          target = h.effective_root
          target = h if target.nil?
        end
        next if target.kind_of? TagContext
        next if target.kind_of? TagWorld
        label = target.name
        results << {
          :name => h.name,
          :label => h.name,
          :family => (target.respond_to? "family") ? target.family : target.class.to_s.underscore.humanize,
          :type => target.class.to_s.underscore.pluralize,
          :id => target.id,
          :pid => target.to_param,
          :is_tag => is_tag
        }
      end
    end
    results = results.group_by{|x| x[:label]}.collect{|n, v| v[0]}
    results.sort!{|a,b| diff(a[:label],b[:label],a[:is_tag],b[:is_tag],search)}
    render :json => results.to_json
  end
  
protected
  def get_latest_changes
    data = Organization.latest_changes(session)
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

  def whittle(lst,name,threshold,limit)
    if lst.length>threshold
      lst2 = lst.select{|o| o.name.downcase.index(name.downcase) == 0}
      if lst2.length > 0
        lst = lst2
      end
    end
    lst[0,limit]
  end

  def diff(a,b,a_tag,b_tag,ref)
    return -1 if a_tag and not b_tag
    return +1 if b_tag and not a_tag
    a = a.downcase
    b = b.downcase
    i1 = a.index(ref.downcase)
    i2 = b.index(ref.downcase)
    return -1 if i2.nil? and not(i1.nil?)
    return +1 if i1.nil? and not(i2.nil?)
    return a <=> b if i1.nil? and i2.nil?
    return a <=> b if i1 == i2
    i1 <=> i2
  end

  def areaize(loc,txt)
    txt = txt.downcase
    if loc.physical_city
      return SearchItem.new(loc.physical_city,"City",{:city => loc.physical_city, :state => loc.physical_state, :country => loc.physical_country}) if loc.physical_city.downcase.include? txt
    end
    if loc.physical_zip
      return SearchItem.new(loc.physical_zip,"Postal code",{:zip => loc.physical_zip, :city => loc.physical_city, :state => loc.physical_state, :country => loc.physical_country}) if loc.physical_zip.downcase.include? txt
    end
    if loc.physical_state
      return SearchItem.new(loc.physical_state,"State",{:state => loc.physical_state, :country => loc.physical_country}) if loc.physical_state.downcase.include? txt
    end
    if loc.physical_country
      return SearchItem.new(loc.physical_country,"Country",{:country => loc.physical_country}) if loc.physical_country.downcase.include? txt
    end
    nil
  end
end
