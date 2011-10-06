class ProductService < ActiveRecord::Base
  belongs_to :organization
  validates_presence_of :name, :organization
  validates_uniqueness_of :name, :scope => :organization_id
  
  def to_s
    self.name
  end
  def <=>(other)
    self.to_s <=> other.to_s
  end
end
