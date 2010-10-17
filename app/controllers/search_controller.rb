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

    # if user is admin, don't append any conditions to search
    unless current_user && current_user.is_admin?
      # if user has a member org, allow user to search for member's entries
#      if current_user && current_user.member
#        @member_clause = "OR member_id:#{current_user.member.id}"
#      end
      # restrict searches to public + (maybe) this member's entries
#      query += " +(public:true #{@member_clause})"
    end

    @latest_changes = get_latest_changes()
    
    if params[:q]
      params[:page] = 1 unless params[:page]
      @entries = ActsAsFerret::find(
                                  query,
                                  [Organization, Person],
                                    { :page => params[:page], :per_page => 15,
                                    },
                                  { 
                                      :limit => :all,
#                                      :conditions => 
#                                      ["((access_rules.access_type = 'PUBLIC') OR (access_rules.access_type = 'LOGGED_IN') OR (access_rules.access_type = 'PRIVATE'))"],
                                      #["(access_rules.access_type = 'PUBLIC' OR (access_rules.access_type = 'LOGGED_IN') OR (access_rules.access_type = 'PRIVATE')"],
                                      # be careful with joins not to mention organization or person
                                      # the organizations_users join doesn't do anything useful for people, but does not cause harm
#                                      :joins => ["LEFT JOIN organizations_users ON organizations_users.organization_id = id", "INNER JOIN access_rules ON access_rules.id = access_rule_id"]
                                    }
                                    )

      # TODO: find a better way to filter entries based on access rules. To use the :conditions option in find_options above, we would need to join through organizations_users to current_user, or join Person directly to current_user - not sure how that works with the multi-table query...

      ## Had to remove this, it was killing pagination
      # @entries = AccessRule.cleanse(@entries, current_user)
      
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
  
protected
  def get_latest_changes
    data = Organization.latest_changes(session[:filters]) + Person.latest_changes(session[:filters])
    logger.debug("data=#{data}")
    data = AccessRule.cleanse(data, current_user).sort{|a,b| b.updated_at <=> a.updated_at}[0..14]
    logger.debug("returning data=#{data}")
    return data
  end

 def windowed_pagination_links(pagingEnum, options)
    link_to_current_page = options[:link_to_current_page]
    always_show_anchors = options[:always_show_anchors]
    padding = options[:window_size] 
    current_page = pagingEnum.page
    html = ''
    padding = padding < 0 ? 0 : padding
    first = pagingEnum.page_exists?(current_page  - padding) ? current_page - padding : 1
    last = pagingEnum.page_exists?(current_page + padding) ? current_page + padding : pagingEnum.last_page
    html << yield(1) if always_show_anchors and not first == 1
    first.upto(last) do |page|
      (current_page == page && !link_to_current_page) ? html << page : html << yield(page)
    end
    html << yield(pagingEnum.last_page) if always_show_anchors and not last == pagingEnum.last_page
    html
  end

end
