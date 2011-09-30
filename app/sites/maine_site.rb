class MaineSite < Site

  def site_searches
    ['food','local sprouts','zip:04412','*']
  end

  def aliases
    ['maine.find.coop','me.find.coop','testme.find.coop']
  end

  def state_filter
    ['Maine', 'ME']
  end

  def should_show_latest_people
    false
  end

  def title
    'Cooperative Maine Directory'
  end
end
