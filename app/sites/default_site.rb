class DefaultSite < Site

  def site_searches
    nil
  end

  def aliases
    ['find.coop', 'www.find.coop', 'proto.find.coop']
  end

  def layout
    :sprint
  end
  
  def blank_search
    'Data Commons'
  end

  def menu
    [
     {
       :name => "About",
       :link => "http://datacommons.find.coop/about"
     },
     {
       :name => "Contact",
       :link => "http://datacommons.find.coop/contact"
     },
     {
       :name => "Donate",
       :link => "http://datacommons.find.coop/donate"
     },
    ]
  end
end
