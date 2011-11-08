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
  def parse_line(entry, dso, default_access_type)
    ########################################################### VALIDATE FUNCTION ARGUMENTS
    unless(dso)
      raise "DSO record was not passed to import()"
    end

    ########################################################### INITIALIZE FUNCTION VARIABLES
    errors = []
    match_status = {}

    ########################################################### READ IN DATA FROM ENTRY
    orgName = entry['Company Name']
    RAILS_DEFAULT_LOGGER.debug("IMPORT: beginning import for #{orgName} ----------------------------------------------------")

    orgs = Organization.find_with_ferret("\"#{orgName}\"")
    unless orgs.nil?
      if orgs.length>1
        orgs = Organization.find_with_ferret("name:\"#{orgName}\"")
      end
    end
    match = nil
    if orgs.nil?
      errors.push "Do not know what to do with #{orgName}"
    elsif orgs.length == 1
      match = orgs.first
      match_status['linked'] = match.data_sharing_orgs.member? dso
    elsif orgs.length == 0
      errors.push "No matches for #{orgName}"
    else
      errors.push "Many matches for #{orgName}"
    end
    entry['name'] = orgName

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
