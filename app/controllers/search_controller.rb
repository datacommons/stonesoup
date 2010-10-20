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
      params[:page] = 1 unless params[:page]
      if current_user
          access_condition = ["access_rules.access_type IN (\'PUBLIC\',\'LOGGED_IN\') OR users.id = ?", current_user.id]
      else
          access_condition = "access_rules.access_type = \'PUBLIC\'"
      end
          
      @entries = ActsAsFerret::find(query,
                                    [Organization, Person],
                                    { 
                                      :page => params[:page], 
                                      :per_page => 15,
                                    },
                                    { 
                                      :limit => :all,
                                      :conditions => access_condition,
                                      :include => [:access_rule,
                                                   :users]
                                    })

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

end
