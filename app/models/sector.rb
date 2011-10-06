class Sector < ActiveRecord::Base
  has_and_belongs_to_many :organizations

  def Sector.get_available
    Sector.find(:all, :order => 'name')
  end

  def to_s
    self.name
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end
end
