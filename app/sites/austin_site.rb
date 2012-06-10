class AustinSite < Site

  def site_searches
    ['wheatsville','Worker Cooperative']
  end

  def aliases
    ['austin.find.coop','testaustin.find.coop']
  end

  def state_filter
    ['Texas', 'TX']
  end
  
  def city_filter
    ['Austin']
  end
  
  def layout
    :sprint
  end

  def use_logo
    true
  end

  def should_show_latest_people
    false
  end

  def menu
    [
     {
       :name => "Austin Co-op Think Tank",
       :link => "http://www.thinktank.coop/"
     },
     {
       :name => "Data Commons Cooperative",
       :link => "http://datacommons.find.coop"
     }
    ]
  end
end
