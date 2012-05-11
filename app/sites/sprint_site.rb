class SprintSite < Site

  def site_searches
    nil
  end

  def aliases
    ['sprint.find.coop', 'testsprint.find.coop', 'proto.find.coop']
  end

  def blank_search
    'Data Commons'
  end

  def layout
    :sprint
  end
end
