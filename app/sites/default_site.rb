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

  def languages
    :all
  end

  def menu
    [
     {
       :name => "About",
       :link => "http://datacommons.find.coop/about"
     },
     {
       :name => "Join",
       :link => "http://datacommons.find.coop/content/member-packet"
     },
     {
       :name => "Contact",
       :link => "http://datacommons.find.coop/contact"
     },
    ]
  end
end
