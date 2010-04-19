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

    if params[:q]
      @entries = Organization.find_with_ferret(query)
      #searcher = Searcher.new(RAILS_ROOT + 'index')
      #@entries = searcher.search(query, :filter_proc => Proc.new{|id,score,searcher| return Organization.find(id).accessible?(current_user)})

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
    @within = within

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
end
