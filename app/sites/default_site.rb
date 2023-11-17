class DefaultSite < Site

  def site_searches
    nil
  end

  def aliases
    ['find.coop', 'www.find.coop', 'test.find.coop', 'proto.find.coop']
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
       :link => "http://datacommons.coop/"
     },
     {
       :name => "Join",
       :link => "https://datacommons.coop/members/join/"
     },
     {
       :name => "Contact",
       :link => "http://datacommons.coop/contact/"
     },
    ]
  end
end
