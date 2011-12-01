require 'import_helper'

module Usfwc

  def parse_line(entry, dso, default_access_type, action)

    unless(dso)
      raise "DSO record was not passed to import()"
    end

    helper = ImportHelper.new

    org_attr = {:name => entry['Company Name'],
      :description => nil,
      :phone => helper.fix_null(entry['Phone']),
      :fax => helper.fix_null(entry['Fax']),
      :email => helper.fix_null(entry['General Email']),
      :website => helper.fix_null(entry['Website']),
      :year_founded => nil,
      :democratic => nil,
      :created_by_id => nil,
      :updated_by_id => nil,
      :created_at => Time.now,
      :updated_at => Time.now,
      :legal_structure_id => nil,
      :primary_location_id => nil}

    loc_attr = {
      :physical_address1 => helper.fix_null(entry['Street Address']),
      :physical_city => helper.fix_null(entry['City']),
      :physical_state => helper.fix_null(entry['State']),
      :physical_zip => helper.fix_null(entry['Postal Code']),
      :physical_country => "United States"
    }

    return helper.apply(dso,default_access_type,action,org_attr,loc_attr)

  end   # end of parse_line()
  module_function :parse_line

end   # end of module
