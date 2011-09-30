class OhioSite < Site

  def site_searches
    ['grocery','zip:43202','*']
  end

  def aliases
    ['ohio.find.coop','oh.find.coop','testoh.find.coop']
  end

  def state_filter
    ['Ohio', 'OH']
  end

  def should_show_latest_people
    false
  end
end
