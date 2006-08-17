class SearchController < ApplicationController
  def index
    search
    render :action => 'search'
  end

  def search
    @entries = Entry.search(params[:q]) if params[:q]
  end
end
