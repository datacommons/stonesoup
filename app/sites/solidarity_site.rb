class SolidaritySite < Site

  def site_searches
    ['GEO']
  end

  def aliases
    ['solidarityeconomy.org','www.solidarityeconomy.org','solidarity.find.coop','testremote.solidarityeconomy.org','test.solidarityeconomy.org','testsolidarity.find.coop' ]
  end

  def should_show_latest_people
    false
  end

  def dso_filter
    ["Solidarity Economy", "US Federation of Worker Cooperatives"]
  end

  def custom_css
    nil
  end
end
