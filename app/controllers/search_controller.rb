class SearchController < ApplicationController
  def index
    search
  end

  def search
    @entries = Entry.search(params[:q]) if params[:q]
  end
end
