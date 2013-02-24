require 'import_helper'

# a weaker coop maine import, to set up links to existing orgs

module Usfwc2013
  # general plugin configuration
  FOREIGN_KEY_FIELD = 'EntryID'
  
  SECTOR_MAP = {
  }

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

    orgName = entry['COMPANY NAME']
    RAILS_DEFAULT_LOGGER.debug("IMPORT: beginning import for #{orgName} ----------------------------------------------------")
    description = ""
    
    if(m = (entry['YEAR FOUNDED'] || '').match(/\b\d{4}\b/))
      year_founded = m[0]
    else
      year_founded = nil
    end
    
    org_attr = {:name => orgName,
      :description => description,
      :phone => entry['CO PHONE'],  
      :email => entry['CO EMAIL'],
      :website => entry['WEBSITE'],
      :year_founded => year_founded,
      :democratic => true}
    RAILS_DEFAULT_LOGGER.debug("IMPORT: basic org attributes are: #{org_attr.inspect}")

    location_attrs = []
    location_attrs.push({
      :physical_address1 => entry['ADDRESS STREET'],
      :physical_address2 => "",
      :physical_city => entry['ADDRESS CITY'],
      :physical_state => entry['ADDRESS STATE'],
      :physical_zip => entry['ADDRESS ZIP'],
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
    proto.tags = [ "Worker Cooperative" ]
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
