class NycSite < Site

  def site_searches
    ['green worker','Brooklyn','food','zip:10036*','*']
  end

  def aliases
    ['nyc.find.coop','testnyc.find.coop']
  end

  def state_filter
    ['New York', 'NY']
  end
  
  def city_filter
    ['New York', 'NYC', 'NY', 'Manhattan', 'Queens', 'Brooklyn', 'Bronx', 'Staten Island', 'Kings', 'Richmond']
  end

  def layout
    :sprint
  end

  def use_logo
    true
  end

  def should_show_latest_people
    false
  end
end
