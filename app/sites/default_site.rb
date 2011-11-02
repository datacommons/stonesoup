class DefaultSite < Site

  def site_searches
    ['Connecticut','cooperative','zip:02139','tech*', 'sector:food AND (organic OR local)','Noemi Giszpenc']
  end

  def aliases
    ['find.coop', 'www.find.coop']
  end

  def blank_search
    'Data Commons'
  end
end
