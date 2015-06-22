class NSFUSSolidarity < Site

  def layout
    :nsfus_solidarity
  end

  def custom_css
    "nsfus_solidarity"
  end

  # ensures that "Examples" doesn't appear below search bar
  # should return a list of example strings if otherwise
  def site_searches
    nil
  end

  def search_bar_in_header
    true
  end

  def should_show_latest_people
    false
  end

  def aliases
    ['ussolidarity', 'ussolecon.parit.ca', 'solidarityeconomy.us', 'dev.solidarityeconomy.us']
  end

  def title
    'US Solidarity Economy Mapping Platform'
  end

  def menu
    [
     {
       :name => "About",
       :link => "/about/",
       :id => "menu_button_about" 
     },
     {
       :name => "Frontpage",
       :link => "/",
       :id => "menu_button_frontpage"
     }
    ]
  end

  def use_logo
    true
  end

  def custom_filters_template
    'layouts/nsfus_solidarity/filters2'
  end

  def custom_search_template
    'layouts/nsfus_solidarity/nsf_list'
  end

end
