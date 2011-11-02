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

  def blank_search
    'startup'
  end
end
