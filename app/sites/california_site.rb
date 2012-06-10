class CaliforniaSite < Site

  def site_searches
    nil
  end

  def aliases
    ['california.find.coop', 'ca.find.coop', 'testca.find.coop']
  end

  def state_filter
    ['California', 'CA']
  end

  def custom_css
    :california
  end

  def layout
    :sprint
  end
  
  def use_logo
    true
  end

  def home
    nil
  end

  def menu
    [
     {
       :name => "Home Page",
       :link => "http://www.cccd.coop/"
     },
     {
       :name => "Donate",
       :link => "https://www.networkforgood.org/donation/ExpressDonation.aspx?ORGID2=392065673"
     },
    ]
  end
end
