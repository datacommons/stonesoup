class SearchController < ApplicationController
  def index
    search
    render :action => 'search'
  end

  def search
    query = params[:q].to_s

    # if user is admin, don't append any conditions to search
    unless current_user && current_user.is_admin?
      # if user has a member org, allow user to search for member's entries
      if current_user && current_user.member
        @member_clause = "OR member_id:#{current_user.member.id}"
      end
      # restrict searches to public + (maybe) this member's entries
      query += " +(public:true #{@member_clause})"
    end

    if params[:q]
      @entries = Entry.find_with_ferret(query) 

      f = params[:format]
      respond_to do |f| 
        f.html
        f.xml { render :xml => @entries }
        f.csv do
          send_data Entry.report_table.to_csv,
          :type => 'text/csv; charset=iso-8859-1; header=present',
          :disposition => ("attachment; filename=search.csv")
        end
      end
    end
  end

  def near
    @entry = Entry.find(params[:id])
    @entries = Entry.find(:all, :origin => @entry, :within=>10, :order=>'distance asc')

    f = params[:format]
    respond_to do |f| 
      f.html
      f.xml { render :xml => @entries }
      f.csv do
        data = [@entries].flatten
        data = data.map {|r| r.reportable_data}.flatten
        cols = data.first.keys
        table = Ruport::Data::Table.new(:data => data,
                                        :column_names => cols)
        send_data(table.to_csv, 
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => ("attachment; filename=search.csv"))
      end
    end
  end
end
