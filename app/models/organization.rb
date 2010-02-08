class Organization < ActiveRecord::Base
  has_many :locations, :dependent => :destroy
  has_many :products_services, :dependent => :destroy
  belongs_to :legal_structure
  belongs_to :access_rule
  has_and_belongs_to_many :org_types
  has_and_belongs_to_many :sectors
  has_and_belongs_to_many :member_orgs
  has_many :organizations_people, :dependent => :destroy
  has_many :people, :through => :organizations_people
  has_and_belongs_to_many :users
end
