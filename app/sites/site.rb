class Site

   def self.inherited(child)
     @@subclasses[self] ||= []
     @@subclasses[self] << child
     super
   end

  @@subclasses = {}
  @@subsites = {}

  def self.get_subclasses
    @@subclasses[self]
  end

  def self.get_subsites
    @@subsites[self]
  end

  def self.get_subsite(name)
    @@subsites[self][name]
  end

  def site_searches
    []
  end

  def aliases
    nil
  end

  def canonical_name
    aliases[0]
  end

  def should_show_latest_people
    true
  end

  def show_latest_graphically
    true
  end

  def state_filter
    nil
  end

  def city_filter
    nil
  end

  def zip_filter
    nil
  end

  def name
    @name ||= self.class.name.gsub('Site','').downcase
  end

  def layout
    :default
  end

  def style
    :default
  end

  def title
    'Data Commons Directory'
  end

  def blank_search
    '*'
  end

  def self.scan
    get_subclasses.each do |c|
      s = c.new
      @@subsites[self] ||= {}
      s.aliases.each do |a| 
        @@subsites[self][a] = s
      end
    end
  end
end

