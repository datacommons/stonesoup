class FciSite < Site

  def site_searches
    ['hmm']
  end

  def aliases
    ['fci.find.coop','testfci.find.coop','coopdirectory.org','www.coopdirectory.org']
  end

  def dso_filter
    nil
  end

  def city_filter
    ["Boston"]
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
    'Coop Directory Service'
  end

  def menu
    [
     {
       :name => "Kris Olsen Memorial",
       :link => { :id => 'kris_olsen' }
     },
     {
       :name => "Seward Community Co-op",
       :link => "http://seward.coop/"
     }
    ]
  end
end
