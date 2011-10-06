class DcSite < Site

  def site_searches
    ['food','zip:20005','agri*','*']
  end

  def aliases
    ['dc.find.coop','testdc.find.coop']
  end

  def state_filter
    ['District of Columbia', 'DC']
  end
  
  def should_show_latest_people
    false
  end
end
