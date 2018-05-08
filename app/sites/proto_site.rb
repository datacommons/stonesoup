class ProtoSite < Site

  def site_searches
    nil
  end

  def aliases
    ['proto2.find.coop', 'test.proto2.find.coop']
  end

  def dso_filter
    nil
  end

  def state_filter
    nil
  end

  def country_filter
    nil
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
    false
  end

  def title
    'Stone Soup directory'
  end

  def home
    'http://proto.find.coop'
  end

  def menu
    [
     {
       :name => "Home",
       :link => "/",
       :id => "manitoba-button-find"
     }
    ]
  end
end
