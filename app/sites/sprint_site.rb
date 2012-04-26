class SprintSite < Site

  def site_searches
    nil
  end

  def aliases
    ['sprint.find.coop', 'testsprint.find.coop']
  end

  def blank_search
    'Data Commons'
  end

  def custom_css
    nil
  end

  def style
    name
  end

  def layout
    name
  end

  def search_bar_in_header
    true
  end
end
