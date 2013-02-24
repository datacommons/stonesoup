require 'import_helper'

module WorkerCoopLaw

  def parse_line(entry, dso, default_access_type, action)
    unless(dso)
      raise "DSO record was not passed to import()"
    end

    errors = []

    null_helper = ImportHelper.new
    entry.to_hash.keys.each do |k|
      entry[k] = null_helper.fix_null(entry[k])
    end

    orgName = entry['Company']
    
    org_attr = {:name => orgName,
      :description => "",
      :phone => entry['Phone'],  
      :fax => entry['Fax'],
      :email => entry['Email'],
      :website => entry['Website']
    }

    location_attrs = []
    location_attrs.push({
      :mailing_address1 => entry['Street'],
      :mailing_address2 => "",
      :mailing_city => entry['City'],
      :mailing_state => entry['State'],
      :mailing_zip => entry['Zip'],
      :mailing_country => entry['Country'],
      :created_at => Time.now,
      :updated_at => Time.now}
    )
    
    contact1_attr = {
      :firstname => entry['First Name'],
      :lastname => entry['Last Name'],
      :phone_mobile => entry['Cell'],
      :phone_home => entry['Phone'],
      :fax => nil,
      :email => entry['Email'],
      :created_at => Time.now,
      :updated_at => Time.now,
    }

    contact1_link_attr = {
      :phone => entry['Phone'],
      :email => entry['Email'],
      :created_at => Time.now,
      :updated_at => Time.now,
    }
    
    contact_attrs = [
                     {
                       :person_attr => contact1_attr,
                       :link_attr => contact1_link_attr,
                     }
                    ]

    proto = ProtoEntry.new
    proto.org_attr = org_attr
    proto.location_attrs = location_attrs
    proto.contact_attrs = contact_attrs
    # proto.org_type_names = org_type_names
    # proto.sector_names = sector_names
    # proto.legal_structure_name = legal_structure_name
    # proto.member_orgs = member_orgs
    # proto.product_service_names = product_service_names
    proto.entry = entry
    proto.default_access_type = default_access_type

    helper = ImportHelper.new
    return helper.apply_proto(dso,action,proto)

  end   # end of parse_line()
  module_function :parse_line

end   # end of module
