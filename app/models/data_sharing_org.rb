class DataSharingOrg < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :data_sharing_orgs_taggables, :dependent => :destroy

  has_many :organizations, :through => :data_sharing_orgs_taggables,
           :source => :organization, :conditions => "data_sharing_orgs_taggables.taggable_type = 'Organization'"

  has_many :people, :through => :data_sharing_orgs_taggables,
           :source => :person, :conditions => "data_sharing_orgs_taggables.taggable_type = 'Person'"

  def taggables
    self.organizations + self.people
  end

  def status_for(org)
    DataSharingOrgsTaggable.get_status(self, org).verified
  end
  
  def num_unverified
    self.data_sharing_orgs_taggables.count(:conditions => 'verified = 0')
  end
  
  def unverified_orgs
    self.data_sharing_orgs_taggables.select{|link| Organization === link.taggable}.reject{|link| link.verified}.map{|link| link.taggable}
  end

  def unverified_entries
    self.data_sharing_orgs_taggables.reject{|link| link.verified}.map{|link| link.taggable}
  end

  def to_s
    self.name
  end
end
