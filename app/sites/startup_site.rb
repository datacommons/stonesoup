class StartupSite < Site

  def site_searches
    ["data commons", "manchester"]
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

  def layout
    :sprint
  end

  def use_logo
    true
  end
end
