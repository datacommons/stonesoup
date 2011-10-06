class LegalStructure < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

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
end
