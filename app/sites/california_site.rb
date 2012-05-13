class CaliforniaSite < Site

  def site_searches
    ['housing','tech*','Arizmendi','zip:941*','*']
  end

  def aliases
    ['california.find.coop', 'ca.find.coop', 'testca.find.coop']
  end

  def state_filter
    ['California', 'CA']
  end

  def should_show_latest_people
    false
  end

  def custom_css
    nil
  end

  def style
    :default
  end

  def layout
    :california
  end
end
