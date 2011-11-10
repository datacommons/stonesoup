module Usfwc

  # general plugin configuration
  # FOREIGN_KEY_FIELD = 'EntryID'
  
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
    match_status = {}

    if action == :add
      org_attr = {:name => entry['Company Name'],
        :description => nil,
        :phone => entry['Phone'],
        :fax => entry['Fax'],
        :email => nil,
        :website => entry['Website'],
        :year_founded => nil,
        :democratic => nil,
        :created_by_id => nil,
        :updated_by_id => nil,
        :created_at => Time.now,
        :updated_at => Time.now,
        :legal_structure_id => nil,
        :primary_location_id => nil}

      organization = Organization.new(org_attr)
      organization.set_access_rule(default_access_type)
      organization.save!
      organization.ferret_update
      return organization
    end

    ########################################################### READ IN DATA FROM ENTRY
    orgName = entry['Company Name']
    RAILS_DEFAULT_LOGGER.debug("IMPORT: beginning import for #{orgName} ----------------------------------------------------")

    seek_name = orgName.gsub(/\(.*\)/,'')
    orgs = Organization.find_with_ferret("\"#{seek_name}\"")
    prev_seek_name = ""
    if orgs.length>1
      orgs = Organization.find_with_ferret("name:\"#{seek_name}\"")
    end
    seek_name = seek_name.gsub(/[^a-zA-Z0-9]/,'* ').gsub(/^ */,'').gsub(/ *$/,'').gsub(/ +/,' ')
    while orgs.length == 0
      prev_seek_name = seek_name
      seek_name = seek_name.gsub(/ [^ ]*$/,'')
      # errors.push "Trying #{prev_seek_name} vs #{seek_name}"
      break if seek_name == prev_seek_name
      orgs = Organization.find_with_ferret("name:\"#{seek_name}\"")
      match_status[:weak] = true
      if orgs.length>1
        orgs = []
        break
      end
    end
    match = nil
    location = Location.new(:physical_address1 => entry['Street Address'], :physical_city => entry['City'], :physical_state => entry['State'])
    if orgs.nil?
      errors.push "Do not know what to do with #{orgName}"
    elsif orgs.length == 1
      match = orgs.first
      match_status[:linked] = match.data_sharing_orgs.member? dso
      unless match_status[:linked]
        if match_status[:weak]
          plausible = false
          match.locations.each do |loc|
            if loc.physical_city == entry['City']
              plausible = true
            end
            if loc.physical_address1 == entry['Street Address']
              plausible = true
            end
          end
          unless plausible
            errors.push "Rejecting implausible match for #{orgName}"
            match = nil
            orgs = []
          end
        end
      end
    end

    if orgs.length == 0
      errors.push "No matches for #{orgName}"
      stub = {:name => orgName,
        :description => nil,
        :phone => entry['Phone'],
        :fax => entry['Fax'],
        :email => entry['General Email'],
        :website => entry['Website'],
        :year_founded => nil,
        :democratic => nil,
        :created_by_id => nil,
        :updated_by_id => nil,
        :created_at => nil,
        :updated_at => nil,
        :legal_structure_id => nil,
        :primary_location_id => nil}
      entry['stub'] = stub
      match_status[:available] = true
    else
      errors.push "Many matches for #{orgName}"
      match_status[:ambiguous] = true
    end
    entry['name'] = orgName
    entry['summary_text'] = entry['Street Address'].to_s + " " + entry['City'].to_s + " " + entry['State'].to_s  + " / " + entry['Website'].to_s

    # return {:record => organization, :record_status => record_status, :errors => errors}
    # errors.push "Nothing doing for #{orgName}"
    return {:errors => errors, :record_status => :processed, 
      :local => entry,
      :remote => match,
      :match_status => match_status
    }
  end   # end of parse_line()
  module_function :parse_line

end   # end of module
