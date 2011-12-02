require 'import_helper'

# a weaker coop maine import, to set up links to existing orgs

module CoopMaineWeak
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

    orgName = entry['Organization Name']
    RAILS_DEFAULT_LOGGER.debug("IMPORT: beginning import for #{orgName} ----------------------------------------------------")
    description = entry['Description of Work']
    description += "\n\nMission:\n" + entry['Mission'] unless entry['Mission'].blank?
    
    if(m = (entry['When Founded?'] || '').match(/\b\d{4}\b/))
      year_founded = m[0]
    else
      year_founded = nil
    end
    
    product_service_names = [ entry['Product/Service 1'], entry['Product/Service 2'], entry['Product/Service 3']].compact
    
    org_attr = {:name => orgName,
      :description => description,
      :phone => entry['Phone1'],  
      :fax => entry['Fax'],
      :email => entry['Email'],
      :website => entry['Website'],
      :year_founded => year_founded,
      :democratic => (entry['Democratic Workplace/Organization?'] == 'TRUE')}
    RAILS_DEFAULT_LOGGER.debug("IMPORT: basic org attributes are: #{org_attr.inspect}")

    location_attrs = []
    location_attrs.push({
      :physical_address1 => entry['L1_Street Address 1'],
      :physical_address2 => entry['L1_Street Address 2'],
      :physical_city => entry['L1_City/Town'],
      :physical_state => entry['L1_State/Province'],
      :physical_zip => entry['L1_Zip/Postal Code'],
      :physical_country => nil,
      :mailing_address1 => entry['L1_Mailing Address 1'],
      :mailing_address2 => entry['L1_Mailing Address 2'],
      :mailing_city => entry['L1_Mailing City/Town'],
      :mailing_state => entry['L1_Mailing State/Province'],
      :mailing_zip => entry['L1_Mailing Zip/Postal Code'],
      :mailing_country => nil,
      :latitude => nil,
      :longitude => nil,
      :created_at => Time.now,
      :updated_at => Time.now}
    )
      
    location_attrs.push({
      :physical_address1 => entry['L2_Street Address '],
      :physical_address2 => entry['L2_Street Address 2'],
      :physical_city => entry['L2_City/Town'],
      :physical_state => entry['L2_State/Province'],
      :physical_zip => entry['L2_Zip/Postal Code'],
      :physical_country => nil,
      :mailing_address1 => entry['L2_Mailing Address '],
      :mailing_address2 => entry['L2_Mailing Address 2'],
      :mailing_city => entry['L2_Mailing City/Town'],
      :mailing_state => entry['L2_Mailing State/Province'],
      :mailing_zip => entry['L2_Mailing Zip/Postal Code'],
      :mailing_country => nil,
      :latitude => nil,
      :longitude => nil,
      :created_at => Time.now,
      :updated_at => Time.now}
      #TODO:   L2_Phone1,   L2_Phone1_ Extension,   L2_Phone2,   L2_Fax
    )

    location_attrs.push({
      :physical_address1 => entry['L3_Street Address '],
      :physical_address2 => entry['L3_Street Address 2'],
      :physical_city => entry['L3_City/Town'],
      :physical_state => entry['L3_State/Province'],
      :physical_zip => entry['L3_Zip/Postal Code'],
      :physical_country => nil,
      :mailing_address1 => entry['L3_Mailing Address '],
      :mailing_address2 => entry['L3_Mailing Address 2'],
      :mailing_city => entry['L3_Mailing City/Town'],
      :mailing_state => entry['L3_Mailing State/Province'],
      :mailing_zip => entry['L3_Mailing Zip/Postal Code'],
      :mailing_country => nil,
      :latitude => nil,
      :longitude => nil,
      :created_at => Time.now,
      :updated_at => Time.now}
      #TODO:   L3_Contact1_Office Phone ,   L3_Contact1_Cell Phone,   L3_Contact1_Home Phone,   L3_Contact1_Email, 
    )

    location_attrs.push({
      :physical_address1 => entry['L4_Street Address '],
      :physical_address2 => entry['L4_Street Address 2'],
      :physical_city => entry['L4_City/Town'],
      :physical_state => entry['L4_State/Province'],
      :physical_zip => entry['L4_Zip/Postal Code'],
      :physical_country => nil,
      :mailing_address1 => entry['L4_Mailing Address '],
      :mailing_address2 => entry['L4_Mailing Address 2'],
      :mailing_city => entry['L4_Mailing City/Town'],
      :mailing_state => entry['L4_Mailing State/Province'],
      :mailing_zip => entry['L4_Mailing Zip/Postal Code'],
      :mailing_country => nil,
      :latitude => nil,
      :longitude => nil,
      :created_at => Time.now,
      :updated_at => Time.now}
      #TODO:   L4_Contact1_Office Phone ,   L4_Contact1_Cell Phone,   L4_Contact1_Home Phone,   L4_Contact1_Email, 
    )

    location_attrs.push({
      :physical_address1 => entry['L5_Street Address 1'],
      :physical_address2 => entry['L5_Street Address 2'],
      :physical_city => entry['L5_City/Town'],
      :physical_state => entry['L5_State/Province'],
      :physical_zip => entry['L5_Zip/Postal Code'],
      :physical_country => nil,
      :mailing_address1 => entry['L5_Mailing Address '],
      :mailing_address2 => entry['L5_Mailing Address 2'],
      :mailing_city => entry['L5_Mailing City/Town'],
      :mailing_state => entry['L5_Mailing State/Province'],
      :mailing_zip => entry['L5_Mailing Zip/Postal Code'],
      :mailing_country => nil,
      :latitude => nil,
      :longitude => nil,
      :created_at => Time.now,
      :updated_at => Time.now}
      #TODO:   'L5_Contact1_Office Phone ', 'L5_Contact1_Cell Phone', 'L5_Contact1_Home Phone', 'L5_Contact1_Email'
    )
    
    contact1_attr = {
      :firstname => entry['L1_Contact1_First Name'],
      :lastname => entry['L1_Contact1_Last Name'],
      :phone_mobile => nil,
      :phone_home => entry['L1_Contact1_Home Phone'],
      :fax => nil,
      :email => entry['L1_Contact1_Email'],
      :phone_contact_preferred => (true|false),
      :email_contact_preferred => (true|false),
      :created_at => Time.now,
      :updated_at => Time.now,
    }
    contact1phone = entry['L1_Contact1_Office Phone 1'] || ''
    contact1phone += ' x' + entry['L1_Contact1_Office Phone 1 Extension'] unless entry['L1_Contact1_Office Phone 1 Extension'].blank?
    contact1_link_attr = {
      :role_name => entry['L1_Contact1_Title/Role 1'],
      :phone => contact1phone,
      :email => entry['L1_Contact1_Email'],
      :created_at => Time.now,
      :updated_at => Time.now,
    }
    
    contact2_attr = {
      :firstname => entry['L1_Contact2_First Name'],
      :lastname => entry['L1_Contact2_Last Name'],
      :phone_mobile => nil,
      :phone_home => entry['L1_Contact2_Home Phone'],
      :fax => nil,
      :email => entry['L1_Contact2_Email'],
      :phone_contact_preferred => (true|false),
      :email_contact_preferred => (true|false),
      :created_at => Time.now,
      :updated_at => Time.now,
    }
    contact2phone = entry['L1_Contact2_Office Phone 1'] || ''
    contact2phone += ' x' + entry['L1_Contact2_Office Phone 1 Extension'] unless entry['L1_Contact2_Office Phone 1 Extension'].blank?
    contact2_link_attr = {
      :role_name => entry['L1_Contact2_Title'],
      :phone => contact1phone,
      :email => entry['L1_Contact2_Email'],
      :created_at => Time.now,
      :updated_at => Time.now,
    }
    contact_attrs = [
                     {
                       :person_attr => contact1_attr,
                       :link_attr => contact1_link_attr,
                     },
                     {
                       :person_attr => contact2_attr,
                       :link_attr => contact2_link_attr,
                     }
                    ]

    # scan for OrgType, Sector, LegalStructure
    # data for these columns is either TRUE, FALSE, or blank (assume FALSE) 
    # except: 'Type: Type of Other1' - string
    # EXCEPT: 'Sector: Specify Other1' - string
    # except: 'Legal: Type of Other' - string

    # process regular named org Type columns
    org_type_names = []
    entry.select{|k,v| k.match(/^Type: (.*)/) and v == 'TRUE'}.each do |k,v|
      if(m = k.match(/^Type: (.*)/))
        org_type_name = m[1]
        if(org_type_name == 'Other')
          # process "other" entries...
          entry.select{|k,v| k.match(/^Type: Type of Other/)}.each do |k,v|
            next if v.blank?
            RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding 'other' Org Type to the list: '#{v}'")
            org_type_names.push(v)
          end
        else  # not 'other', a regular entry, add it as normal
          org_type_names.push(org_type_name)
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding named Org Type to the list: '#{org_type_name}'")
        end
      end
    end
    
    # process regular named Sector columns
    sector_names = []
    entry.select{|k,v| k.match(/^Sector: (.*)/) and v == 'TRUE'}.each do |k,v|
      if(m = k.match(/^Sector: (.*)/))
        sector_name = m[1]
        if(sector_name == 'Other')
          # process "other" entries...
          entry.select{|k,v| k.match(/^Sector: Specify Other/)}.each do |k,v|
            next if v.blank?
            RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding 'other' Sector to the list: '#{v}'")
            sector_names.push(v)
          end
        else  # not 'other', a regular entry, add it as normal
          sector_names.push(sector_name)
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding named Sector to the list: '#{sector_name}'")
        end
      end
    end
    
    # process regular named Legal columns
    legal_structure_name = nil
    entry.select{|k,v| k.match(/^Legal: (.*)/) and v == 'TRUE'}.each do |k,v|
      if(m = k.match(/^Legal: (.*)/))
        legal_name = m[1]
        if(legal_name == 'Other')
          # process "other" entry...
          unless(legal_structure_name.nil?)
            msg = "Warning: Legal Structure was previously set to '#{legal_structure_name}', now overwritten as '#{entry['Legal: Type of Other']}'"
            errors.push(msg)
            RAILS_DEFAULT_LOGGER.warn('IMPORT: ' + msg)
          end
          legal_structure_name = entry['Legal: Type of Other']
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Using 'other' Legal structure: '#{legal_structure_name}'")
        else  # not 'other', a regular entry, set it as normal
          unless(legal_structure_name.nil?)
            msg = "Warning: Legal Structure was previously set to '#{legal_structure_name}', now overwritten as '#{legal_name}'"
            errors.push(msg)
            RAILS_DEFAULT_LOGGER.warn('IMPORT: ' + msg)
          end
          legal_structure_name = legal_name
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Using named Legal structure: '#{legal_structure_name}'")
        end
      end
    end
    
    member_orgs = []
    if(entry['Unionized?'] == 'TRUE')
      union_name = entry['Which Union?']
      unless(union_name.blank?)
        member_orgs.push(MemberOrg.find_or_create_custom(union_name))
      end
    end
    RAILS_DEFAULT_LOGGER.debug("IMPORT: member orgs: #{member_orgs.inspect}")

    proto = ProtoEntry.new
    proto.org_attr = org_attr
    proto.location_attrs = location_attrs
    proto.contact_attrs = contact_attrs
    proto.org_type_names = org_type_names
    proto.sector_names = sector_names
    proto.legal_structure_name = legal_structure_name
    proto.member_orgs = member_orgs
    proto.product_service_names = product_service_names
    proto.entry = entry
    proto.default_access_type = default_access_type

    helper = ImportHelper.new
    return helper.apply_proto(dso,action,proto)

  end   # end of parse_line()
  module_function :parse_line

end   # end of module
