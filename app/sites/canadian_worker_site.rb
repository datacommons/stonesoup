class CanadianWorkerSite < Site

  def site_searches
    ['collective']
  end

  def aliases
    ['canadianworker.find.coop','testcanadianworker.find.coop']
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
       :name => "Data Commons Cooperative",
       :link => "http://datacommons.find.coop"
     },
    ]
  end

  def use_logo
    true
  end
end
