class ManitobaSite < Site

  def site_searches
    ['Winnipeg','housing', 'music']
  end

  def aliases
    ['find.manitoba.coop','manitoba.find.coop','testmanitoba.find.coop']
  end

  def dso_filter
    ["Manitoba Cooperative Association"]
  end

  def state_filter
    ["Manitoba"]
  end

  def country_filter
    ["Canada","CA"]
  end

  def should_show_latest_people
    false
  end

  def layout
    :sprint
  end

  def custom_css
    name
  end

  def use_logo
    true
  end

  def title
    'Manitoba Cooperative Association Inc.'
  end

  def home
    'http://manitoba.coop'
  end

  def menu
    [
     {
       :name => "Find a Co-op",
       :link => "/",
       :id => "manitoba-button-find"
     }
    ]
  end
end
