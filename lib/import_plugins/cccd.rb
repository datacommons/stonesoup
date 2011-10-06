# import plugin for CCCD's California Cooperative Directory

module Cccd

  # general plugin configuration
  FOREIGN_KEY_FIELD = 'ID'
  COOP_TYPE_MAP = { #TODO: fill out these values based on CCCD's preferences 
    'Agriculture' => nil,
    'Arts & Crafts' => nil,
    'Business/Shared Services' => nil,
    'Child Care' => nil,
    'Consumer/Food' => nil,
    'Consumer/Service & Retail' => nil,
    'Credit Union' => nil,
    'Funeral Home/Memorial' => nil,
    'Housing' => nil,
    'Student' => nil,
    'Utility' => nil,
    'Worker' => nil
  }
  
  # inputs: entry (CSV line) , DSO record
  # outputs: result hash including the following keys:
  # => :record (organization record, if any)
  # => :record_status (:error, :created, :updated)
  # => :errors (array of error messages)
  def parse_line(entry, dso, default_access_type)
    unless(dso)
      raise "DSO record was not passed to import()"
    end
    errors = []
    # read in the current data
    orgName = entry['Co-op/Org Name']
    csvOrgType = entry['Org Type']
    coopType = entry['Co-op Type']
    orgType = nil
    if csvOrgType == 'Co-op'
      orgTypeName = [coopType]
      if orgTypeName.nil?
        errors.push "orgType '#{orgTypeName}' is unknown"
      else
        orgType = OrgType.find_by_name(orgTypeName)
        if orgType.nil?
          errors.push "orgType '#{orgTypeName}' is known, but OrgType record was not found"
        end
      end
    else
      errors.push "Unknown Co-op Type in spreadsheet: '#{csvOrgType}' on line #{lines_read}"
    end

    org_attr = {:name => orgName,
      :description => nil,
      :phone => entry['Telephone'],
      :fax => entry['Fax'],
      :email => entry['General Email'],
      :website => entry['Web Page'],
      :year_founded => nil,
      :democratic => nil,
      :created_by_id => nil,
      :updated_by_id => nil,
      :created_at => nil,
      :updated_at => nil,
      :legal_structure_id => nil,
      :primary_location_id => nil}

    loc_attr = {
      :physical_address1 => entry['Street address'],
      :physical_address2 => nil,
      :physical_city => entry['Street City'],
      :physical_state => entry['Street ST'],
      :physical_zip => entry['Street Zip'],
      :physical_county => (entry['Street City'].blank? ? nil : entry['County']),
      :physical_country => (entry['Street City'].blank? ? nil : 'USA'),
      :mailing_address1 => entry['Mailing address'],
      :mailing_address2 => nil,
      :mailing_city => entry['City'],
      :mailing_state => entry['ST'],
      :mailing_zip => entry['Zip'],
      :mailing_county => (entry['City'].blank? ? nil : entry['County']),
      :mailing_country => (entry['City'].blank? ? nil : 'USA'),
      :latitude => nil,
      :longitude => nil,
      :created_at => Time.now,
      :updated_at => Time.now}

    begin
      Organization.transaction do
        # 1st: look for existing organization by foreign key
        fkid = entry[FOREIGN_KEY_FIELD]
        organization = DataSharingOrgsOrganization.find_linked_org(dso, fkid)
        if(organization.nil?)
          # next, try looking for entry with same name (?)
          organization = Organization.find_by_name(orgName)
          unless(organization.nil?)
            # if found, link it to this DSO
            DataSharingOrgsOrganization.linked_org_to_dso(organization, dso, fkid)
          end
        end
        
        if organization.nil?
          # if we still couldn't find it, create a new entry
          organization = Organization.new(org_attr)
          organization.set_access_rule(default_access_type) # set initial access options based on import preferences
          organization.org_types.push orgType unless orgType.nil? or organization.org_types.include?(orgType)
          organization.save!
          record_status = :created
          # and link it to this DSO
          DataSharingOrgsOrganization.linked_org_to_dso(organization, dso, fkid)
        else
          org_attr.reject!{|k,v| v.nil?}  # only update attributes that actually have values
          organization.update_attributes!(org_attr)
          record_status = :updated
        end
  
        if organization.locations.empty?
          location = organization.locations.new(loc_attr).save!
        else
          loc_attr.reject!{|k,v| v.nil?}  # only update attributes that actually have values
          loc_attr.delete(:created_at)  # don't update this one
          organization.locations[0].update_attributes!(loc_attr)
        end
        
        return {:record => organization, :record_status => record_status, :errors => errors}
      end   # Organization.transaction (updating organization & related records)
      
    rescue ActiveRecord::RecordNotSaved => e
      errors.push "Couldn't save record for #{orgName}: #{e}"
      return {:errors => errors, :record_status => :error}
    end
  end   # end of parse_line()
  module_function :parse_line

end   # end of module