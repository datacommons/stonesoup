class DemoSite < Site

  def site_searches
    ['Connecticut','cooperative','zip:02139','tech*', 'sector:food AND (organic OR local)','Noemi Giszpenc']
  end

  def aliases
    ['demo.find.coop', 'testdemo.find.coop']
  end

  def layout
    :demo
  end

end
