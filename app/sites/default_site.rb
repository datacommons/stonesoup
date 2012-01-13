class DefaultSite < Site

  def site_searches
    ['Startup','Connecticut','cooperative','zip:01301','tech*', 'sector:food AND (organic OR local)']
  end

  def aliases
    ['find.coop', 'www.find.coop']
  end

  def blank_search
    'Data Commons'
  end
end
