class DataSharingOrgsOrganization < ActiveRecord::Base
  belongs_to :organization
  belongs_to :data_sharing_org

  def DataSharingOrgsOrganization.find_linked_org(dso, fkid)
    dsoo = DataSharingOrgsOrganization.find(:first, :conditions => ['data_sharing_org_id = ? AND foreign_key_id = ?', dso.id, fkid])
    if dsoo.nil?
      return nil
    else
      return dsoo.organization
    end
  end
  
  def DataSharingOrgsOrganization.linked_org_to_dso(org, dso, fkid)
    link = get_status(dso, org)
    if(link.nil?)
      link = DataSharingOrgsOrganization.new(:data_sharing_org_id => dso.id, :organization_id => org.id)
    end
    link.foreign_key_id = fkid
    link.save!
  end
  
  def DataSharingOrgsOrganization.get_status(dso, org)
    DataSharingOrgsOrganization.find(:first, :conditions => ['data_sharing_org_id = ? AND organization_id = ?', dso.id, org.id])
  end
  
  def DataSharingOrgsOrganization.set_status(dso, org, verified)
    link = get_status(dso, org)
    if(link.nil?)
      link = DataSharingOrgsOrganization.new(:data_sharing_org_id => dso.id, :organization_id => org.id)
    end
    link.verified = verified
    link.save!
  end
end
