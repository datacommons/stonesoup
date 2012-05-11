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
    if not params[:q]
      @latest_changes = get_latest_changes()
      return
    end

    @query = params[:q].to_s + ''
    @search_text = @query
    search_query = params[:q].to_s + '' # apparently the (+ '') is needed to make these distinct variables

    _params = params.clone
    if search_query == "" and _params[:advanced] != '1'
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

    if name.length>2
      tags = Tag.find(:all, :conditions => [template,value], :limit => limit)
    else
      tags = Tag.find(:all, :conditions => ["name LIKE ? or name LIKE ?",name+"%"," "+name+"%"], :limit => limit)
    end
    if name.length>1
      organizations = Organization.find(:all, :conditions => [template,value], :limit => limit*5)
    end
    if name.length>=2
      first, last = name.split(/ /)
      unless last.nil?
        last = nil if last == ""
      end
      unless last.nil?
        people = Person.find(:all, :conditions => ["lastname LIKE ? AND firstname LIKE ?",last + "%",first + "%"], :limit => limit)
      else
        people = Person.find(:all, :conditions => ["lastname LIKE ? OR firstname LIKE ?",first + "%",first+"%"], :limit => limit)
      end
    end
    if name.length>=2
      locations = Location.find(:all, :conditions => ["physical_address1 LIKE ? OR physical_city LIKE ?",value,value], :limit => limit)
    end
    results = []

    groups = [tags, organizations, people, locations]

    groups.each do |result_set|
      result_set.sort!{|a,b| diff(a.name,b.name,search)}
    end

    global_limit = 25

    if groups.flatten.length>global_limit
      organizations = self.whittle(organizations,name,useful_limit,limit)
      groups = [tags, organizations, people, locations]
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
      groups = [tags, organizations, people, locations]
    end

    groups.each do |result_set|
      result_set.each do |h|
        target = h
        if h.respond_to? "effective_root"
          target = h.effective_root
          target = h if target.nil?
        end
        next if target.kind_of? TagContext
        next if target.kind_of? TagWorld
        label = target.name
        results << {
          :name => h.name,
          :label => h.name,
          :family => target.class.to_s.underscore.pluralize,
          :id => target.id
        }
      end
    end
    results = results.group_by{|x| x[:label]}.collect{|n, v| v[0]}
    results.sort!{|a,b| diff(a[:label],b[:label],search)}
    render :json => results.to_json
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

  def whittle(lst,name,threshold,limit)
    if lst.length>threshold
      lst2 = lst.select{|o| o.name.downcase.index(name.downcase) == 0}
      if lst2.length > 0
        lst = lst2
      end
    end
    lst[0,limit]
  end

  def diff(a,b,ref)
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
end
