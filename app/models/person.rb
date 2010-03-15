class Person < ActiveRecord::Base
  belongs_to :access_rule
  has_many :organizations_people, :dependent => :destroy
  has_many :organizations, :through => :org_associations
  has_one :user
  def name
    firstname + ' ' + lastname
  end  
end
