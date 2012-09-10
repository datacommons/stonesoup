class UsworkerSite < Site

  def site_searches
    ['food','red and black','collective']
  end

  def aliases
    ['usworker.find.coop','testusworker.find.coop','usworkertest.find.coop']
  end

  def should_show_latest_people
    false
  end

  def dso_filter
    ["US Federation of Worker Cooperatives"]
  end

  def custom_css
    name
  end
  
  def layout
    :sprint
  end

  def use_logo
    true
  end

 def menu
    [
     {
       :name => "US Federation of Worker Cooperatives",
       :link => "http://www.usworker.coop"
     },
     {
       :name => "Data Commons Cooperative",
       :link => "http://datacommons.find.coop"
     },
    ]
  end
end
