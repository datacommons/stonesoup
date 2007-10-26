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

    @entries = Entry.find_with_ferret(query) if params[:q]
  end
end
