class OrgType < ActiveRecord::Base
  has_and_belongs_to_many :organizations
end