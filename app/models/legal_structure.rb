class LegalStructure < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :tags, :as => :root

  def LegalStructure.find_or_create_custom(name)
    ls = LegalStructure.find_by_name(name)
    if(ls.nil?)
      ls = LegalStructure.new(:name => name, :custom => true)
      ls.save!
    end
    return ls
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
    {:controller => 'legal_structures', :action => 'show', :id => self.id}
  end

  def accessible?(u)
    true
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end
end
