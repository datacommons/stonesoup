class UsworkerSite < Site

  def site_searches
    []
  end

  def aliases
    ['usworker.find.coop','testusworker.find.coop']
  end

  def should_show_latest_people
    false
  end

  def blank_search
    'us federation of worker'
  end
end
