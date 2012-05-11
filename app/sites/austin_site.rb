class AustinSite < Site

  def site_searches
    ['wheatsville','zip:78704','hous*','*']
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
