class Sector < ActiveRecord::Base
  has_and_belongs_to_many :organizations

  has_many :tags, :as => :root

  def Sector.get_available
    Sector.find(:all, :order => 'name')
  end

  def to_s
    self.name
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end

  def link_name
    name
  end
  
  def link_hash
    {:controller => 'sectors', :action => 'show', :id => self.id}
  end

  def accessible?(u)
    true
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end 
end
