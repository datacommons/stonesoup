class CanadianWorkerSite < Site

  def site_searches
    ['collective']
  end

  def aliases
    ['canadianworker.find.coop','testcanadianworker.find.coop']
  end

  def should_show_latest_people
    false
  end

  def dso_filter
    ["Canadian Worker Cooperative Federation"]
  end

  #def custom_css
  #  name
  #end
end