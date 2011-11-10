# import plugin for CCCD's California Cooperative Directory

module CoopMaine
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

    ########################################################### FIND/CREATE RELATED RECORDS

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
    

    ########################################################### CREATE/UPDATE THE DATABASE RECORDS

    begin
      Organization.transaction do
        # 1st: look for existing organization by foreign key
        fkid = entry[FOREIGN_KEY_FIELD]
        organization = DataSharingOrgsOrganization.find_linked_org(dso, fkid)
        unless(organization.nil?)
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Found existing organization record by Foreign Key ID")
        else
          # next, try looking for entry with same name (?)
          organization = Organization.find_by_name(orgName)
          unless(organization.nil?)
            # if found, link it to this DSO
            DataSharingOrgsOrganization.linked_org_to_dso(organization, dso, fkid)
            RAILS_DEFAULT_LOGGER.debug("IMPORT: Found existing organization record by name ('#{orgName}'), linked to DSO")
          end
        end
        
        if organization.nil?
          # if we still couldn't find it, create a new entry
          organization = Organization.new(org_attr)
          organization.set_access_rule(default_access_type) # set initial access options based on import preferences
          record_status = :created
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Creating new Organization record")
        else
          org_attr.reject!{|k,v| v.blank?}  # only update attributes that actually have values
          organization.update_attributes!(org_attr)
          record_status = :updated
          RAILS_DEFAULT_LOGGER.debug("IMPORT: updated basic org attributes for existing record")
        end
        
        # save the organization record
        # Many related records below depend on having a valid organization_id
        organization.save!
        RAILS_DEFAULT_LOGGER.debug("IMPORT: Organization record was successfully saved.")

        # and link it to this DSO
        DataSharingOrgsOrganization.linked_org_to_dso(organization, dso, fkid)
        RAILS_DEFAULT_LOGGER.debug("IMPORT: Organization record was linked to DSO '#{dso.name}'.")
        
        
        
        # now process org_type_names, loading or creating as necessary...
        RAILS_DEFAULT_LOGGER.debug("IMPORT: setting org's org_types to: #{org_type_names.inspect}")
        organization.org_types = org_type_names.collect{|name| OrgType.find_or_create_custom(name.strip)}
        
        # process legal structure, loading or creating as necessary
        unless(legal_structure_name.blank?)
          RAILS_DEFAULT_LOGGER.debug("IMPORT: setting org's legal_structure to: #{legal_structure_name}")
          organization.legal_structure = LegalStructure.find_or_create_custom(legal_structure_name.strip)
        end
        
        # process sectors: find/link or report error
        organization.sectors = []
        RAILS_DEFAULT_LOGGER.debug("IMPORT: setting org's sectors to: #{sector_names.inspect}")
        sector_names.each do |sector_name|
          sector_name = SECTOR_MAP[sector_name] unless SECTOR_MAP[sector_name].nil? # if there's a mapped value, use it
          sector = Sector.find_by_name(sector_name.strip)
          if(sector.nil?)
            msg = "Sector not found for '#{sector_name}' - import value should be updated to match existing selections or new Sector must be added by Admin."
            RAILS_DEFAULT_LOGGER.error('IMPORT: ' + msg)
            errors.push(msg)
          else
            organization.sectors.push(sector)
          end
        end
        
        # link in member orgs, if any
        current_member_org_names = organization.member_orgs.map(&:name).sort
        new_member_org_names = member_orgs.map(&:name).sort
        if(current_member_org_names != new_member_org_names)
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Current MO names: #{current_member_org_names.inspect}")
          RAILS_DEFAULT_LOGGER.debug("IMPORT: New MO names: #{new_member_org_names.inspect}")
          # first, remove any now missing
          organization.member_orgs.each do |mo|
            unless current_member_org_names.include?(mo.name)
              RAILS_DEFAULT_LOGGER.debug("IMPORT: Removing MemberOrg: #{mo.name}")
              mo.destroy
            end
          end
          # next, add any new ones
          new_member_org_names.each do |mo_name|
            unless(current_member_org_names.include?(mo_name))
              RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding MemberOrg: #{mo_name}")
              organization.member_orgs.push(MemberOrg.find_or_create_custom(mo_name))
            end
          end
          RAILS_DEFAULT_LOGGER.debug("IMPORT: After update, new MO names: #{organization.member_orgs.map(&:name).inspect}")
        end
        
        # link in products/services, if new/changed
        current_ps_names = organization.products_services.map(&:name)
        if(current_ps_names.sort != product_service_names.sort)
          # lists are different, need to update...
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Current PS names: #{current_ps_names.inspect}")
          RAILS_DEFAULT_LOGGER.debug("IMPORT: New PS names: #{product_service_names.inspect}")
          # first, remove any now missing
          organization.products_services.each do |ps|
            unless product_service_names.include?(ps.name)
              RAILS_DEFAULT_LOGGER.debug("IMPORT: Removing Product/Service: #{ps.name}")
              ps.destroy
            end
          end
          # next, add any new ones
          product_service_names.each do |ps_name|
            unless(current_ps_names.include?(ps_name))
              RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding Product/Service: #{ps_name}")
              ps = organization.products_services.create(:name => ps_name)
              ps.save!
            end
          end
          RAILS_DEFAULT_LOGGER.debug("IMPORT: After update, new PS names: #{organization.products_services.map(&:name).inspect}")
        end
        
        # set primary location to the first if not already set
        if organization.primary_location.nil? and organization.locations.any?
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Setting primary location to first available.")
          organization.primary_location = organization.locations.first
        end
        
        # create person records for each above, if populated
        # and link people to org with link data
        if(organization.people.any?)
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Clearing existing People linked to organization")
          # NOTE: similar decision here to Locations NOTE above, easier to replace existing contacts with import data
          # rather than trying to detect changes and update records
          organization.people.destroy_all
        end
        contact1 = Person.new(contact1_attr)
        if(contact1.valid?)
          contact1.set_access_rule(default_access_type)
          contact1.save!
          contact1_link = OrganizationsPerson.new(contact1_link_attr)
          contact1_link.person_id = contact1.id
          contact1_link.organization_id = organization.id
          contact1_link.save!
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Added contact1 & linked to org: #{contact1.name}")
        else
          RAILS_DEFAULT_LOGGER.debug("IMPORT: contact1 is invalid: #{contact1.errors.full_messages.inspect}")
        end
        contact2 = Person.new(contact2_attr)
        if(contact2.valid?)
          contact2.set_access_rule(default_access_type)
          contact2.save!
          contact2_link = OrganizationsPerson.new(contact2_link_attr)
          contact2_link.person_id = contact2.id
          contact2_link.organization_id = organization.id
          contact2_link.save!
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Added contact2 & linked to org: #{contact2.name}")
        else
          RAILS_DEFAULT_LOGGER.debug("IMPORT: contact2 is invalid: #{contact2.errors.full_messages.inspect}")
        end
        
        
        
        # update org locations
        # NOTE: this must happen *after* organization.save! because Location requires a valid OrganizationID
        unless organization.locations.empty?
          RAILS_DEFAULT_LOGGER.debug("IMPORT: clearing existing Locations")
          # NOTE: trying to match new locations with existing locations (to update them) is a very complex problem
          # I think in this case it will be easier to just delete all/re-create the locations.
          # This will create more ID turnover in the DB (since some locations will be deleted & re-created exactly the same, but with a different ID)
          # BGCB 2011-10-05
          organization.locations.delete_all
        end
        
        if organization.locations.empty?
          # easy, just create them...
          location_attrs.each do |loc_attr|
            loc_attr[:physical_country] = 'USA' unless loc_attr[:physical_state].blank?
            loc_attr[:mailing_country] = 'USA' unless loc_attr[:mailing_state].blank?
            loc = organization.locations.new(loc_attr)
            if(loc.valid?)
              RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding Location to organization: #{loc.physical_address1} / #{loc.physical_city}")
              loc.save!
            else
              RAILS_DEFAULT_LOGGER.debug("IMPORT: Location is invalid: #{loc.errors.full_messages.inspect}")
            end
          end
        end
        

        return {:record => organization, :record_status => record_status, :errors => errors}
      end   # Organization.transaction (updating organization & related records)
    rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
      RAILS_DEFAULT_LOGGER.error("Couldn't save record for #{orgName}")
      RAILS_DEFAULT_LOGGER.error(e)
      errors.push "Couldn't save record for #{orgName}: #{e}"
      return {:errors => errors, :record_status => :error}
    end
  end   # end of parse_line()
  module_function :parse_line

end   # end of module
