class ProtoEntry
  attr_accessor :org_attr, :location_attrs, :contact_attrs
  attr_accessor :org_type_names, :sector_names, :legal_structure_name
  attr_accessor :member_orgs
  attr_accessor :product_service_names
  attr_accessor :entry
  attr_accessor :default_access_type
  attr_accessor :tags

  def from_org(org)
    self.org_attr = org
    self.location_attrs = org.locations
    self.contact_attrs = []
    org.organizations_people.each do |op|
      self.contact_attrs.push({
                                :person => op.person,
                                :link => op
                              })
    end
    self.org_type_names = org.org_types.collect{|x| x.name}
    self.sector_names = org.sectors.collect{|x| x.name}
    self.legal_structure_name = nil
    self.legal_structure_name = org.legal_structure.name unless org.legal_structure.nil?
    self.tags = org.tags.collect{|x| x.name}
    # more to do ...
    true
  end

  def to_hash_part(part)
    return nil if part.nil?
    if part.respond_to?(:attributes)
      return part.attributes
    end
    if part.respond_to?(:map)
      # return part.keys
      return Hash[*part.map{ |key, val| [key, to_part(val)]}.flatten]
    end
    return part.to_s
  end

  def to_part(part)
    return nil if part.nil?
    if part.respond_to?(:each)
      return part.collect{ |x| self.to_part(x) }
    end 
    to_hash_part(part)
  end

  def to_hashlist_part(part)
    return nil if part.nil?
    if part.respond_to?(:each)
      return part.collect{ |x| self.to_hash_part(x) }
    end 
    to_hash_part(part)
  end

  def to_hash
    {
      :org => to_part(org_attr),
      :locations => to_part(location_attrs),
      :contacts => to_hashlist_part(contact_attrs),
      :org_type_names => to_part(org_type_names),
      :sector_names => to_part(sector_names),
      :legal_structure_name => to_part(legal_structure_name),
      :member_orgs => to_part(member_orgs),
      :product_service_names => to_part(product_service_names),
      :tags => to_port(tags),
    }
  end
end
