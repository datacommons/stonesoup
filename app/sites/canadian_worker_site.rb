class CanadianWorkerSite < Site

  def site_searches
    ['collective']
  end

  def aliases
    ['canadianworker.find.coop','testcanadianworker.find.coop','cwcftest.find.coop']
  end

  def should_show_latest_people
    false
  end

  def dso_filter
    ["Canadian Worker Cooperative Federation"]
  end

  def layout
    :sprint
  end

  def menu
    [
     {
       :name => "Canadian Worker Co-op Federation",
       :link => "http://www.canadianworker.coop"
     },
     {
       :name => "DCC",
       :link => "http://datacommons.find.coop"
     },
    ]
  end

  def use_logo
    true
  end

  def canadian_by_default
    true
  end
end
