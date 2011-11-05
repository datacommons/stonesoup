class StartupSite < Site

  def site_searches
    []
  end

  def aliases
    ['startup.find.coop','teststartup.find.coop']
  end

  def should_show_latest_people
    false
  end

  def org_type_filter
    ['Startup']
  end

  def blank_search
    '*'
  end
end
