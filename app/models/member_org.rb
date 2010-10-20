class MemberOrg < ActiveRecord::Base
  has_and_belongs_to_many :organizations
  belongs_to :synonym_of, :class_name => 'MemberOrg', :foreign_key => 'effective_id'
  has_many :synonyms, :class_name => 'MemberOrg', :foreign_key => 'effective_id'
  
  def get_organizations
    Organization.find(:all, :conditions => ['x.member_org_id = ? OR member_orgs.effective_id = ?', self.id, self.id],
      :joins => 'INNER JOIN member_orgs_organizations x ON x.organization_id = organizations.id
 INNER JOIN member_orgs ON x.member_org_id = member_orgs.id')
  end
  
  def root_term(original_root = self)
    return self if synonym_of.nil?
    if original_root == synonym_of  # prevent cirles
      logger.error("Detected a synonym circle! starting with: #{original_root.inspect}")
      return original_root 
    end
    return synonym_of.root_term(original_root)
  end
  
  def MemberOrg.get_available
    MemberOrg.find(:all, :conditions => 'custom = 0 AND (effective_id IS NULL OR effective_id = id)', :order => 'name')
  end
  
  def link_name
    self.name
  end
  
  def link_hash
    {:controller => 'member_orgs', :action => 'show', :id => self}
  end
end
