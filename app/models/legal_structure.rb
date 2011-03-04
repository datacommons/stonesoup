class LegalStructure < ActiveRecord::Base
  validates_presence_of :name

  def to_s
    self.name
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end
end
