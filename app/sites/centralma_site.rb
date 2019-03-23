class CentralmaSite < Site

  def site_searches
    ['Worcester']
  end

  def aliases
    ['centralma.find.coop','testcentralma.find.coop']
  end

  def dso_filter
    ["Solidarity and Green Economy Alliance"]
  end

  def should_show_latest_people
    false
  end

  def layout
    :sprint
  end

  def use_logo
    true
  end

  def title
    'Central Massachusetts Directory'
  end

  def menu
    [
     {
       :name => "Solidarity and Green Economy Alliance",
       :link => "http://www.worcestersagealliance.org/"
     },
    ]
  end
end
