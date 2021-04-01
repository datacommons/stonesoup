class MaineSite < Site

  def site_searches
    ['Belfast food','local sprouts','fisher*']
  end

  def aliases
    ['maine.find.coop','me.find.coop','testme.find.coop', 'mainetest.find.coop']
  end

  def dso_filter
    ["Cooperative Maine"]
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
    'Cooperative Maine Directory'
  end

  def menu
    [
     {
       :name => "Cooperative Maine",
       :link => "https://maine.coop/"
     },
     {
       :name => "Data Commons Cooperative",
       :link => "http://datacommons.find.coop"
     },
    ]
  end
end
