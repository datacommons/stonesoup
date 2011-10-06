class DataSharingOrg < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :data_sharing_orgs_organizations, :dependent => :destroy
  has_many :organizations, :through => :data_sharing_orgs_organizations
  def status_for(org)
    DataSharingOrgsOrganization.get_status(self, org).verified
  end
  
  def unverified_orgs
    self.data_sharing_orgs_organizations.reject{|link| link.verified}.map{|link| link.organization}
  end
end
