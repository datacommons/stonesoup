class SearchController < ApplicationController

  # before_filter :login_required, :only => [:inspect]

  before_filter(:only => [:search, :map, :near]) do |controller|
    controller.send(:login_required) if ['json', 'kml', 'pdf', 'csv', 'yaml', 'xml'].include? controller.request.format
  end

public

  def index
    if params[:q] || params[:act]
      search
      render :action => 'search'
    else
      @welcome_page = true
      render :action => 'welcome'
    end
  end

  def test
    _params = {}
    @entries, @counts, @counts_dsos = @template.search_core(_params,@site,{ 
                                                              :unlimited_search => true 
                                                            }, true)
    @entries.reject!{|e| e.kind_of? Person}
    @entries.uniq!
    @entries.sort!{|a,b| a.oname <=> b.oname}
    render :layout => "#{@site.layout}/printable", :template => "layouts/#{@site.name}/_directory"
  end

  def test_leaflet
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

    @entries, @counts, @counts_dsos = @template.search_core(_params,@site,{ :unlimited_search => @unlimited_search, :params => _params }, true)

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

    if @unlimited_search
      @map_style = true
    end
    if params[:q]
      render_entries
    end
  end

  def map
    @unlimited_search = true
    @map_style = true
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
    if @unlimited_search
      @entries = @entries.paginate(:per_page => 50000, :page => 1)
    else
      @entries = @entries.paginate(:per_page => 15, :page => (params[:page]||1))
    end

    render_entries
  end
  
  def render_js
#    render :file => 'main/render_js', :use_full_path => true
    #<%= render :file => 'rendered_includes/' + params[:src] + '.rhtml' %>
    render :file => 'rendered_includes/' + params[:src] + '.rhtml'
  end

  def mini_map
    @name = params[:name]
    @link = YAML::load(params[:link])
    @orgs = @template.get_listing_for_link(@name,@link,@site.name)
    @rendered = true
    render :partial => "search/map"
  end

  def mini_map2
    @name = params[:name]
    @link = YAML::load(params[:link])
    @orgs = @template.get_listing_for_link(@name,@link,@site.name)
    @rendered = true
    render :partial => "search/map2"
  end

  def change_filter
    if params[:name]
      key = ("active_" + params[:name] + "_filter").to_sym
      if params[:value]
        session[key] = params[:value].split(/;/).map{|x| x.strip}
      else
        # key = nil means use default; key = [] means filter inactive
        if session[key].nil?
          session[key] = []
        else
          session[key] = nil
        end
        if key == :active_within_filter
          session[:active_loc_filter] = nil
        end
      end
    end
    reset = params[:act] == "reset"
    if reset
      @active_filters.each do |f|
        session["active_#{f[:name]}_filter".to_sym] = nil
      end
    end
    if params[:act] and not(reset)
      adding = ( params[:act] != "remove" and not(reset))
      params.select{|k,v| k.include? "_filter"}.each do |k,v|
        k = "dso_filter" if k == "data_sharing_orgs_filter"
        k = k.gsub("s_filter","_filter")
        key = "active_" + k
        record = session[key.to_sym]
        record = [] if session[key.to_sym].nil? or key == "active_within_filter"
        if adding
          record << v
        else
          record.delete(v)
        end
        record.uniq!
        record.sort!
        session[key.to_sym] = record
      end
      if params.keys.include? "zip_filter"
        session[:active_city_filter] = nil
      elsif params.keys.include? "city_filter"
        session[:active_zip_filter] = nil
      end
    end
    self.get_filters
    render :partial => 'filters2'
  end

  def auto_complete_test
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
    auto_complete_tag_core("OrgType",opts)
  end

  def auto_complete_sector
    opts = { :omit => [:sector_filter] }
    auto_complete_tag_core("Sector",opts)
  end

  def auto_complete_legal_structure
    opts = { :omit => [:legal_structure_filter] }
    auto_complete_tag_core("LegalStructure",opts)
  end

  def auto_complete_member_org
    opts = { }
    auto_complete_tag_core("MemberOrg",opts)
  end

  def auto_complete_tag
    opts = { }
    auto_complete_tag_core(nil,opts)
  end

  def auto_complete_tag_all
    search = params[:search]
    search = "" if search.nil?
    name = search
    template = "name LIKE ?"
    value = (name.length>2 ? "%" : "")+name+"%"
    limit = 50
    tags = Tag.find(:all, :conditions => [template, value], :limit => limit, :select => 'DISTINCT tags.*')
    results = []
    tags.each do |h|
      root = h.effective_root
      next if root.kind_of? TagContext
      next if root.kind_of? TagWorld
      label = h.literal_qualified_name
      results << {
        :name => h.name,
        :label => label,
        :id => h.id,
        :root_name => root ? root.name : nil,
        :root_link => root ? @template.url_for(root) : nil
        }
    end
    results.sort!{|a,b| diff(a[:label],b[:label],true,true,search)}
    logger.debug("Result #{results.to_json}")
    render :json => results.to_json
  end

  def auto_complete_root_all
    search = params[:search]
    search = "" if search.nil?
    name = search
    template = "name LIKE ?"
    value = (name.length>2 ? "%" : "")+name+"%"
    limit = 50
    models = [LegalStructure, MemberOrg, OrgType, Sector]
    tags = []
    models.each do |model|
      tags << model.find(:all, :conditions => [template, value], :limit => limit)
    end
    results = []
    tags.flatten.each do |h|
      root = nil
      label = h.name
      results << {
        :name => h.name,
        :label => label,
        :id => h.id,
        :root_type => h.class.to_s,
        :root_link => @template.url_for(root)
        }
    end
    results.sort!{|a,b| diff(a[:label],b[:label],true,true,search)}
    logger.debug("Result #{results.to_json}")
    render :json => results.to_json
  end

  def auto_complete_dso
    auto_complete_named(DataSharingOrg,{})
  end

  def auto_complete_within
    search = params[:search]
    search = "" if search.nil?
    tags = []
    country_filter = ApplicationHelper.get_filter(session,:country_filter)
    units = ["miles","kilometers"]
    unless country_filter.blank?
      # eventually make this more sophisticated (use country associated
      # with zip code / other origin)
      if country_filter.include? "Canada"
        units = ["kilometers","miles"]
      end
    end
    standards = [10, 20, 50]
    units.each do |u|
      standards.each do |x|
        tags << SearchItem.new("#{x} #{u}","within",{ :within => "#{x} #{u}" })
      end
    end
    x = search.to_i
    if x > 0 and not(standards.include? x)
      units.each do |u|
        tags << SearchItem.new("#{x} #{u}","within",{ :within => "#{x} #{u}" })
      end
    end
    if search.length > 0
      tags.reject!{|t| t.name.index(search.downcase) != 0}
    end

    render_auto_complete([tags],search,{:should_sort => false})
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

    state_first = false

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
      tags = Tag.find(:all, :conditions => conditions, :joins => joinSQL, :limit => limit, :select => 'DISTINCT tags.*')
    end

    if name.length>=1
      joinSQL, condSQLs, condParams = Organization.all_join(session)
      joinSQL = nil if condSQLs.empty?
      condSQLs << template.gsub("name","organizations.name")
      condParams << value
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      organizations = Organization.find(:all, :conditions => conditions, :joins => joinSQL, :limit => limit*5, :group => 'coalesce(grouping, organizations.id)')
    end

    if name.length>=2
      first, last = name.split(/ /)
      unless last.nil?
        last = nil if last == ""
      end
      joinSQL, condSQLs, condParams = Organization.all_join(session,{ :entity => "Person"})
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
      joinSQL = "INNER JOIN organizations ON organizations.id = locations.taggable_id AND locations.taggable_type = 'Organization' #{joinSQL}"
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
      joinSQL = "INNER JOIN organizations ON organizations.id = locations.taggable_id AND locations.taggable_type = 'Organization' #{joinSQL}"
      condSQLs = condSQLs + locCondSQLs
      condParams = condParams + locCondParams
      joinSQL = nil if condSQLs.empty?
      alt = Location::STATE_SHORT[name.upcase]
      if alt.nil?
        condSQLs << "locations.physical_city LIKE ? OR locations.physical_state LIKE ? OR locations.physical_country LIKE ? OR locations.physical_zip LIKE ?"
        condParams << value
        condParams << value
        condParams << value
        condParams << value
      else
        condSQLs << "locations.physical_state = ?"
        condParams << alt
      end
      conditions = []
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      area_locations = Location.find(:all, :conditions => conditions, 
                                     :joins => joinSQL,
                                     :limit => limit)
      areas = area_locations.map{|x| areaize(x,name)}.compact.uniq
      unless alt.nil?
        if areas.length>0
          state_first = true
        end
      end
    end

    groups = [tags, areas, organizations, people, locations]

    groups.each do |result_set|
      result_set.sort!{|a,b| diff(a.name,b.name,false,false,search)}
    end

    global_limit = 25

    if groups.flatten.length>global_limit
      if areas.length>0
        locations = []
      end
    end

    if groups.flatten.length>global_limit
      organizations = self.whittle(organizations,name,useful_limit,limit)
      groups = [tags, areas, organizations, people, locations]
    end

    if groups.flatten.length>global_limit
      curr_len = groups.flatten.length
      last_len = -1
      while curr_len>global_limit and curr_len!=last_len
        groups.each_with_index do |result_set,idx|
          if idx==0
            if result_set.length<global_limit*0.5
              next
            end
          end
          result_set.slice!((result_set.length*0.8).floor,result_set.length)
        end
        groups = [tags, areas, organizations, people, locations]
        last_len = curr_len
        curr_len = groups.flatten.length
      end
    end
    opts = {}
    opts[:state_first] = true if state_first
    render_auto_complete(groups,search,opts)
  end

  def page
    render :template => "layouts/#{@site.name}/#{params[:id]}"
  end

protected
  def get_latest_changes
    data = Organization.latest_changes(session)
    data = data + Person.latest_changes(session).uniq
    logger.debug("data=#{data}")
    # data = AccessRule.cleanse(data, current_user)...
    data = data.sort{|a,b| ( a.updated_at and b.updated_at ) ? b.updated_at <=> a.updated_at : ( b.updated_at ? 1 : -1 )}
    if data.length>50
      data = data[0..49]
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
    if field != "physical_state"
      return nil unless val.downcase.include? txt
    end
    if field == "physical_city"
      return SearchItem.new(loc.physical_city,"City",{:city => loc.physical_city, :state => loc.physical_state, :country => loc.physical_country}) 
    elsif field == "physical_zip"
      zip = loc.physical_zip.sub(/-.*/,'')
      return SearchItem.new(zip,"Postal code",{:zip => zip, :city => loc.physical_city, :state => loc.physical_state, :country => loc.physical_country})
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

  def render_auto_complete(groups,search, opts = {})
    should_sort = true
    should_root = true
    should_sort = opts[:should_sort] unless opts[:should_sort].nil?
    should_root = opts[:should_root] unless opts[:should_root].nil?
    negated = opts[:negated] || false
    state_first = opts[:state_first]
    results = []
    groups.each do |result_set|
      result_set.each do |h|
        target = h
        is_tag = false
        if h.respond_to? "effective_root" and should_root
          is_tag = true
          target = h.effective_root
          target = h if target.nil?
        end
        if state_first
          is_tag = (target.respond_to? "family") ? target.family == "State" : false
        end
        next if target.kind_of? TagContext
        next if target.kind_of? TagWorld
        label = target.name
        prefix = negated ? "-" : ""
        if label.length>0
          results << {
            :name => prefix + h.name,
            :label => prefix + h.name,
            :family => (target.respond_to? "family") ? target.family : target.class.to_s.underscore.humanize,
            :type => target.class.to_s.underscore.pluralize,
            :id => target.id,
            :pid => target.to_param,
            :is_tag => is_tag
          }
        end
      end
    end
    if should_sort
      results = results.group_by{|x| x[:label]}.collect{|n, v| v[0]}
      results.sort!{|a,b| diff(a[:label],b[:label],a[:is_tag],b[:is_tag],search)}
    end
    if params[:fallback]
      if params[:fallback] == "1"
        matches = "no exact match"
        if (results.length>0) 
          matches = "matches found" 
        end
        results << { :fallback => search, :name => "#{search}; #{matches}", :pid => { params[:base].sub(/_filter/,'') => search } }
      end
    end
    logger.debug("Result #{results.to_json}")
    render :json => results.to_json
  end

  def auto_complete_location(key,opts,distinct_sql = nil)
    search = params[:search]
    search = "" if search.nil?
    name = search
    template = "name LIKE ?"
    value = (name.length>2 ? "%" : "")+name+"%"
    limit = 50
    limit = 50 + params[:limit].to_i if params[:limit]
    areas = []
    if name.length>=0
      ignore, locCondSQLs, locCondParams = Organization.location_join(session,opts)
      joinSQL, condSQLs, condParams = Organization.tag_join(session,opts)
      joinSQL = "INNER JOIN organizations ON organizations.id = locations.taggable_id AND locations.taggable_type = 'Organization' #{joinSQL}"
      condSQLs = condSQLs + locCondSQLs
      condParams = condParams + locCondParams
      joinSQL = nil if condSQLs.empty?
      alt = nil
      alt = Location::STATE_SHORT[name.upcase] if key == "physical_state"
      if alt.nil?
        condSQLs << "locations.#{key} LIKE ?"
        condParams << value
      else
        condSQLs << "(locations.#{key} LIKE ?) OR (locations.#{key} = ?)"
        condParams << value
        condParams << alt
      end
      logger.debug("Working on #{key} / #{value} / #{name} / #{alt} / #{search}")
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

  def auto_complete_tag_core(key,opts)
    search = params[:search]
    search = "" if search.nil?
    negated = search.starts_with?("-")
    search.gsub!(/^-/,"") if negated
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
      tags = Tag.find(:all, :conditions => conditions, :joins => joinSQL, :limit => limit, :select => 'DISTINCT tags.*')
    end
    render_auto_complete([tags],search,{:negated => negated})
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
