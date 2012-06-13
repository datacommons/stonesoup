class DataSharingOrgsTaggable < ActiveRecord::Base
  belongs_to :taggable, :polymorphic => true
  belongs_to :data_sharing_org

  belongs_to :organization, :class_name => "Organization", :foreign_key => "taggable_id"
  belongs_to :person, :class_name => "Person", :foreign_key => "taggable_id"

  def DataSharingOrgsTaggable.find_linked_taggable(dso, fkid)
    dsoo = DataSharingOrgsTaggable.find(:first, :conditions => ['data_sharing_org_id = ? AND foreign_key_id = ?', dso.id, fkid])
    if dsoo.nil?
      return nil
    else
      return dsoo.taggable
    end
  end

  def DataSharingOrgsTaggable.find_linked_org(dso, fkid)
    org = DataSharingOrgsTaggable.find_linked_taggable
    return nil if org.nil?
    return nil unless Organization === org
    org
  end

  def DataSharingOrgsTaggable.linked_org_to_dso(org, dso, fkid)
    DataSharingOrgsTaggable.linked_taggable_to_dso(org,dso,fkid)
  end
  
  def DataSharingOrgsTaggable.linked_taggable_to_dso(org, dso, fkid)
    link = get_status(dso, org)
    if(link.nil?)
      link = DataSharingOrgsTaggable.new(:data_sharing_org_id => dso.id, :taggable => org)
    end
    link.foreign_key_id = fkid
    link.save!
  end
  
  def DataSharingOrgsTaggable.get_status(dso, org)
    DataSharingOrgsTaggable.find(:first, :conditions => ['data_sharing_org_id = ? AND taggable_id = ? AND taggable_type = ?', dso.id, org.id, org.class.to_s])
  end
  
  def DataSharingOrgsTaggable.set_status(dso, org, verified)
    link = get_status(dso, org)
    if(link.nil?)
      link = DataSharingOrgsTaggable.new(:data_sharing_org_id => dso.id, :taggable => org)
    end
    link.verified = verified
    link.save!
  end
end
