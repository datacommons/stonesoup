class NSFUSSolidarity < Site

  def languages
    [:es, :en]
  end

  def layout
    :sprint
  end

  def custom_css
    "nsfussolidarity"
  end

  # ensures that "Examples" doesn't appear below search bar
  # should return a list of example strings if otherwise
  def site_searches
    nil
  end

  def should_show_latest_people
    false
  end

  def country_filter
    ["United States"]
  end

  def aliases
    ['ussolidarity', ]
  end

  def dso_filter
    ["NSF_US_solidarity"]
  end

  def title
    'US Solidarity Economy Mapping Platform'
  end

  def menu
    [
     {
       :name => "Frontpage",
       :link => "/",
     }
    ]
  end
end
