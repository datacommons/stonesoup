class PlumbingController < ApplicationController
  before_filter :admin_required

  def index
    Organization.rebuild_index
  end

  def org
    @orgs = Organization.find(:all)
    @orgs.each do |org|
      org.ferret_update
    end
  end

  def ppl
    @data = Person.find(:all)
    @data.each do |datum|
      datum.ferret_update
    end
  end

  def show
    @locs = Location.find_all_by_latitude(nil, :limit => 10)
    @locs.each do |l|
      l.save_ll
      l.save(false)
    end
  end

  def email
    ModeratorMailer::deliver_mail("paulfitz@localhost")
  end

end

