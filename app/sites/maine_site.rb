class MaineSite < Site

  def site_searches
    ['food','local sprouts','zip:04412','*']
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
       :link => "http://www.cooperativemaine.org/"
     },
     {
       :name => "Data Commons Cooperative",
       :link => "http://datacommons.find.coop"
     },
    ]
  end
end
