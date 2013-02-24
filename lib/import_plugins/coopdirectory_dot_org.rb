require 'import_helper'

# a weaker coop maine import, to set up links to existing orgs

module CoopdirectoryDotOrg
  # general plugin configuration
  FOREIGN_KEY_FIELD = 'MailingListID'
  
  SECTOR_MAP = {
  }

  def self.fixup_email(x) 
    return nil if x.nil?
    x.sub(/#.*/,'')
  end

  def self.fixup_web(x) 
    return nil if x.nil?
    return x unless x.include? "#"
    if x[0] == "#"
      return x.sub(/#/,'')

    end
    x.sub(/#.*/,'')
  end

  # inputs: entry (CSV line) , DSO record
  # outputs: result hash including the following keys:
  # => :record (organization record, if update/create was successful)
  # => :record_status (:error, :created, :updated)
  # => :errors (array of error messages)
  def parse_line(entry, dso, default_access_type, action)
    ########################################################### VALIDATE FUNCTION ARGUMENTS
    unless(dso)
      raise "DSO record was not passed to import()"
    end

    ########################################################### INITIALIZE FUNCTION VARIABLES
    errors = []

    ########################################################### READ IN DATA FROM ENTRY

    nully = ImportHelper.new
    entry.to_hash.keys.each do |k|
      entry[k] = nully.fix_null(entry[k])
    end

    orgName = entry['CompanyName']
    RAILS_DEFAULT_LOGGER.debug("IMPORT: beginning import for #{orgName} ----------------------------------------------------")
    description = ""
    
    year_founded = nil
    
    org_attr = {:name => orgName,
      :description => description,
      :phone => entry['WorkPhone'],  
      :fax => entry['FaxNumber'],  
      :email => fixup_email(entry['Email Address']),
      :website => fixup_web(entry['Web Address']),
      :year_founded => year_founded}
    RAILS_DEFAULT_LOGGER.debug("IMPORT: basic org attributes are: #{org_attr.inspect}")

    location_attrs = []
    location_attrs.push({
      :physical_address1 => entry['Address'],
      :physical_address2 => "",
      :physical_city => entry['City'],
      :physical_state => entry['State'],
      :physical_zip => entry['PostalCode'],
      :physical_country => "United States",
      :mailing_address1 => nil,
      :mailing_address2 => nil,
      :mailing_city => nil,
      :mailing_state => nil,
      :mailing_zip => nil,
      :mailing_country => nil,
      :latitude => nil,
      :longitude => nil,
      :created_at => Time.now,
      :updated_at => Time.now}
    )
      
    proto = ProtoEntry.new
    proto.org_attr = org_attr
    proto.location_attrs = location_attrs
    #proto.contact_attrs = contact_attrs

    proto.tags = []
    cat = entry['Category']
    cat.downcase! unless cat.nil?
    proto.tags << ["OrgType","Food Cooperative"] if cat == "coop"
    proto.tags << "Buying Club" if cat == "buying club" || cat == "bc" 
    proto.tags << ["Sector","Food"] 
    #proto.sector_names = sector_names
    #proto.legal_structure_name = legal_structure_name
    #proto.member_orgs = member_orgs
    #proto.product_service_names = product_service_names
    proto.entry = entry
    proto.default_access_type = default_access_type

    helper = ImportHelper.new
    return helper.apply_proto(dso,action,proto)

  end   # end of parse_line()
  module_function :parse_line

end   # end of module
