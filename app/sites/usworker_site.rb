class UsworkerSite < Site

  def site_searches
    ['GAIA Host','collective']
  end

  def aliases
    ['usworker.find.coop','testusworker.find.coop']
  end

  def should_show_latest_people
    false
  end

  def dso_filter
    ["US Federation of Worker Cooperatives"]
  end

  def blank_search
    'us federation of worker'
  end
end
