class PlumbingController < ApplicationController
  before_filter :login_required, :only => [:index]

  def index
    Organization.rebuild_index
  end

end

