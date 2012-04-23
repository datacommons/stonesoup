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
    name
  end

  def style
    name
  end

  def layout
    name
  end
end
