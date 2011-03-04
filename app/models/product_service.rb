class ProductService < ActiveRecord::Base
  belongs_to :organization
  def to_s
    self.name
  end
  def <=>(other)
    self.to_s <=> other.to_s
  end
end
