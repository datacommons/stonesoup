class SearchController < ApplicationController
  def index
    if params[:q] || params[:act]
      search
      render :action => 'search'
    else
      @latest_changes = get_latest_changes
      render :action => 'welcome'
    end
  end

  def search
    params[:q] = "" unless params[:q]
    @query = params[:q].to_s + ''
    @search_text = @query
    search_query = params[:q].to_s + '' # apparently the (+ '') is needed to make these distinct variables

    _params = params.clone
    # if search_query == "" and _params[:advanced] != '1' and not(params[:act])
    # search_query = @site.blank_search
    #  _params[:q] = search_query
    #end

    @entries = @template.search_core(_params,@site)

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

  def feed
    @entries = get_latest_changes
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
    render :layout => false
  end

  def recent
    @title = "Recently changed"
    @entries = get_latest_changes
    @entries = @entries.paginate(:per_page => 15, :page => (params[:page]||1))
  end
  
  def render_js
#    render :file => 'main/render_js', :use_full_path => true
    #<%= render :file => 'rendered_includes/' + params[:src] + '.rhtml' %>
    render :file => 'rendered_includes/' + params[:src] + '.rhtml'
  end

  def change_filter
    if params[:name]
      key = ("active_" + params[:name] + "_filter").to_sym
      if params[:value]
        session[key] = params[:value].split(/,/).map{|x| x.strip}
      else
        # key = nil means use default; key = [] means filter inactive
        if session[key].nil?
          session[key] = []
        else
          session[key] = nil
        end  
      end
    end
    if params[:act]
      params.select{|k,v| k.include? "_filter"}.each do |k,v|
        k = "dso_filter" if k == "data_sharing_orgs_filter"
        k = k.gsub("s_filter","_filter")
        key = "active_" + k
        session[key.to_sym] = [] if session[key.to_sym].nil?
        session[key.to_sym] << v
        session[key.to_sym].uniq!
        session[key.to_sym].sort!
      end
      if params.keys.include? "zip_filter"
        session[:active_city_filter] = nil
      elsif params.keys.include? "city_filter"
        session[:active_zip_filter] = nil
      end
    end
    self.get_filters
    render :partial => 'filters'
  end

  def auto_complete_test
    self.get_filters
    render :action => 'auto_complete_test'
  end

  def auto_complete_country
    opts = { :omit => [:city_filter, :zip_filter, :state_filter, :country_filter] }
    auto_complete_location("physical_country",opts)
  end

  def auto_complete_state
    opts = { :omit => [:city_filter, :zip_filter, :state_filter] }
    auto_complete_location("physical_state",opts)
  end

  def auto_complete_city
    opts = { :omit => [:city_filter, :zip_filter] }
    auto_complete_location("physical_city",opts)
  end

  def auto_complete_zip
    opts = { :omit => [:city_filter, :zip_filter] }
    auto_complete_location("physical_zip",opts)
  end

  def auto_complete_org_type
    opts = { :omit => [:org_type_filter] }
    auto_complete_tag("OrgType",opts)
  end

  def auto_complete_sector
    opts = { :omit => [:sector_filter] }
    auto_complete_tag("Sector",opts)
  end

  def auto_complete_legal_structure
    opts = { :omit => [:legal_structure_filter] }
    auto_complete_tag("LegalStructure",opts)
  end

  def auto_complete_dso
    auto_complete_named(DataSharingOrg,{})
  end

  def auto_complete
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
    render_auto_complete(groups,search)
  end
  
protected
  def get_latest_changes
    data = Organization.latest_changes(session)
    data = data + Person.latest_changes(session).uniq
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

  def areaize1(field,loc,txt)
    txt = txt.downcase
    val = loc[field]
    return nil unless val
    val.strip!
    return nil if val == ""
    return nil unless val.downcase.include? txt
    if field == "physical_city"
      return SearchItem.new(loc.physical_city,"City",{:city => loc.physical_city, :state => loc.physical_state, :country => loc.physical_country}) 
    elsif field == "physical_zip"
      return SearchItem.new(loc.physical_zip,"Postal code",{:zip => loc.physical_zip, :city => loc.physical_city, :state => loc.physical_state, :country => loc.physical_country})
    elsif field == "physical_state"
      return SearchItem.new(loc.physical_state,"State",{:state => loc.physical_state, :country => loc.physical_country})
    elsif field == "physical_country"
      return SearchItem.new(loc.physical_country,"Country",{:country => loc.physical_country})
    end
    nil
  end

  def areaize(loc,txt)
    return areaize1("physical_city",loc,txt) || areaize1("physical_zip",loc,txt) || areaize1("physical_state",loc,txt) || areaize1("physical_country",loc,txt)
  end

  def render_auto_complete(groups,search)
    results = []
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

  def auto_complete_location(key,opts,distinct_sql = nil)
    search = params[:search]
    search = "" if search.nil?
    name = search
    template = "name LIKE ?"
    value = (name.length>2 ? "%" : "")+name+"%"
    limit = 50
    areas = []
    if name.length>=0
      ignore, locCondSQLs, locCondParams = Organization.location_join(session,opts)
      joinSQL, condSQLs, condParams = Organization.tag_join(session,opts)
      joinSQL = "INNER JOIN organizations ON organizations.id = locations.organization_id #{joinSQL}"
      condSQLs = condSQLs + locCondSQLs
      condParams = condParams + locCondParams
      joinSQL = nil if condSQLs.empty?
      condSQLs << "locations.#{key} LIKE ?"
      condParams << value
      sql = 'DISTINCT locations.physical_country'
      condSQLs << "locations.physical_country IS NOT NULL AND locations.physical_country <> ''"
      unless key == "physical_country"
        sql << ", locations.physical_state"
        # condSQLs << "locations.physical_state IS NOT NULL AND locations.physical_state <> ''"
        unless key == "physical_state"
          sql << ", locations.physical_city"
          unless key == "physical_city"
            sql << ", locations.physical_zip"
          end
        end
      end
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      area_locations = Location.find(:all, :conditions => conditions, 
                                     :select => sql,
                                     :joins => joinSQL,
                                     :limit => limit)
      areas = area_locations.map{|x| areaize1(key,x,name)}.compact.uniq
    end
    render_auto_complete([areas],search)
  end

  def auto_complete_tag(key,opts)
    search = params[:search]
    search = "" if search.nil?
    name = search
    template = "name LIKE ?"
    value = (name.length>2 ? "%" : "")+name+"%"
    limit = 50
    tags = []
    if name.length>=0
      joinSQL, condSQLs, condParams = Organization.all_join(session,opts)
      joinSQL = nil if condSQLs.empty?
      if joinSQL
        joinSQL = "INNER JOIN taggings ON taggings.tag_id = tags.id INNER JOIN organizations ON taggings.taggable_id = organizations.id #{joinSQL}"
        condSQLs.unshift("taggings.taggable_type = ?")
        condParams.unshift("Organization")
      end
      if key
        condSQLs.unshift("tags.root_type = ?")
        condParams.unshift(key)
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
    render_auto_complete([tags],search)
  end

  def auto_complete_named(model,opts)
    search = params[:search]
    search = "" if search.nil?
    name = search
    template = "name LIKE ?"
    value = (name.length>2 ? "%" : "")+name+"%"
    limit = 50
    tags = []
    if name.length>=0
      tags = model.find(:all, :conditions => [template, value], :limit => limit)
    end
    render_auto_complete([tags],search)
  end
end
