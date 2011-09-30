class DefaultSite < Site

  def site_searches
    ['"Northeast Biodiesel"','Connecticut','cooperative','zip:02139','sector:consumer', 'sector:nonprofit AND state:massachusetts', 'tech*', 'sector:food AND (organic OR local)','sector:food -organic','Noemi Giszpenc']
  end

  def aliases
    ['find.coop', 'www.find.coop']
  end
end
