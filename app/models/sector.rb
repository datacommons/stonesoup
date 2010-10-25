class Sector < ActiveRecord::Base
  has_and_belongs_to_many :organizations
  def Sector.get_available
    Sector.find(:all, :order => 'name')
  end
end
