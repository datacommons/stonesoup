require 'import_helper'

module Cwcf

  def parse_line(entry, dso, default_access_type, action)

    unless(dso)
      raise "DSO record was not passed to import()"
    end

    helper = ImportHelper.new

    desc_src = "http://www.canadianworker.coop/basics/members"
    desc = helper.fix_null(entry['description'])
    if desc
      if desc.length>60
        desc = desc[0..60]
        if desc.rindex(" ")
          desc = desc[0..(desc.rindex(" "))]
        end
        desc = desc + " ... (<a href='#{desc_src}'>source</a>)"
      end
    end

    org_attr = {:name => helper.fix_null(entry['title']),
      :description => desc,
      :phone => nil,
      :fax => nil,
      :email => helper.fix_null(entry['email']),
      :website => helper.fix_null(entry['website']),
      :year_founded => nil,
      :democratic => nil,
      :created_by_id => nil,
      :updated_by_id => nil,
      :created_at => Time.now,
      :updated_at => Time.now,
      :legal_structure_id => nil,
      :primary_location_id => nil}

    loc_attr = {
      :physical_address1 => helper.fix_null(entry['street']),
      :physical_city => helper.fix_null(entry['city']),
      :physical_state => helper.fix_null(entry['province']),
      :physical_zip => nil,
      :physical_country => "Canada"
    }

    return helper.apply(dso,default_access_type,action,org_attr,loc_attr,entry)

  end   # end of parse_line()
  module_function :parse_line

end   # end of module
