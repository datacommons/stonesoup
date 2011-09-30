class NycSite < Site

  def site_searches
    ['food','zip:10036*','*']
  end

  def aliases
    ['nyc.find.coop','testnyc.find.coop']
  end

  def state_filter
    ['New York', 'NY']
  end
  
  def city_filter
    ['New York', 'NYC', 'NY']
  end

  def should_show_latest_people
    false
  end
end
