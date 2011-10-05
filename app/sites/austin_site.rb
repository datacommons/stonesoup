class AustinSite < Site

  def site_searches
    ['food','zip:10036*','*']
  end

  def aliases
    ['austin.find.coop','testaustin.find.coop']
  end

  def state_filter
    ['Texas', 'TX']
  end
  
  def city_filter
    ['Austin']
  end

  def should_show_latest_people
    false
  end
end
