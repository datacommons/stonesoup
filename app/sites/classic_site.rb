class ClassicSite < Site

  def site_searches
    ['Startup','Connecticut','cooperative','zip:01301','tech*', 'sector:food AND (organic OR local)']
  end

  def aliases
    ['classic.find.coop', 'testclassic.find.coop']
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
