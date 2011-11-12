class SolidaritySite < Site

  def site_searches
    ['CSA']
  end

  def aliases
    ['solidarityeconomy.org','www.solidarityeconomy.org','solidarity.find.coop','testremote.solidarityeconomy.org','test.solidarityeconomy.org','testsolidarity.find.coop' ]
  end

  def should_show_latest_people
    false
  end

  def dso_filter
    nil
  end

  def custom_css
    nil
  end
end
