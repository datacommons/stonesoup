#!./script/runner

require 'nsf_db'
require 'solr_update'

# from import_helper, should be done with require
def fix_null_and_blank(a)
  if a == "NULL" or a == ""
    nil
  else
    a
  end
end

ActiveRecord::Base.transaction do
  StoneToSolidarity.delete_all
  Location.delete_all
  Organization.delete_all
  OrgType.delete_all
  Tag.delete_all

  solr_con = SOLR_SEARCH::create_solr_connection()
  SOLR_SEARCH::solr_delete_all(solr_con)

  type_tags = {}
  NSF_DB::Type.all.each do |t|
    # only use types that are in use
    if t != nil and t.organizations.length > 0
      ot = OrgType.new(:name => t.type_name, :description => t.type_name)
      ot.save!
      org_tag = Tag.new(:root=> ot, :name => t.type_name )
      org_tag.save!
      type_tags[t.tid] = org_tag
    end
  end

  current_org = nil
  current_org_stone = nil

  # this is memory intensive, but we're doing a similar memory
  # intensive operation below, maybe the whole thing should be one
  # custom query and perhaps then some paging could be done
  # to not waste so much memory
  #
  # oh well, nobody is complaining when the dataset is 30,000 locations
  locations_lid_long_lat = NSF_DB::Location.find_by_sql(
     "select " +
     "lid, " +
     "ST_X(geographic_location::geometry) as longitude, " + # longitude
     "ST_Y(geographic_location::geometry) as latitude " +  # latitude
     "from locations;"
  )
  locations_lid_long_lat_table =
    Hash[ locations_lid_long_lat.map{
          |locations_lid_long_lat|
          [locations_lid_long_lat.id,
           locations_lid_long_lat]
          } ]

  # this is very memory intensive, and :order isn't allowed for find_each
  # so we would have to keep in memory or in some kind of secondary storage
  # a tracking of orgs anyway, might as well do it here
  NSF_DB::Location.all(:order => 'oid').each do |l|
    o = l.organization
    if (nil !=
        NSF_DB::Suggestion.find(:first,
                                :conditions => {:organization_id => o.id}) or
        o.ally or o.defunct or o.hide_from_site)
      next
    end

    org_types = []
    if current_org == nil or o.oid != current_org.oid
      current_org = o
      current_org_stone = Organization.new(:name => current_org.name)
      current_org_stone.set_access_rule(AccessRule::ACCESS_TYPE_PUBLIC)
      o.types.each do |org_type|
        current_org_stone.tags << type_tags[org_type.tid]
        org_types << type_tags[org_type.tid].name
      end
      current_org_stone.save!
      orig_key_save = StoneToSolidarity.new(:stoneid=>current_org_stone.id,
                                            :solidarityid=>current_org.oid)
      orig_key_save.save!
    end

    # there are only 24 entries without city, StoneSoup requires one
    city = fix_null_and_blank(l.city)
    country = fix_null_and_blank(l.country)

    # set to nil if not found in existing database
    if locations_lid_long_lat_table.key?(l.lid)
      longitude = locations_lid_long_lat_table[l.lid].longitude
      latitude = locations_lid_long_lat_table[l.lid].latitude
    # we should also use this some time to find out which database entries
    # lack geocoding
    else
      longitude = nil
      latitude = nil
    end

    if city != nil and country != nil
      loc = current_org_stone.locations.new(:note => l.location_name,
                                            :physical_address1 =>
                                            fix_null_and_blank(l.address),
                                            :physical_address2 =>
                                            fix_null_and_blank(l.address2),
                                            :latitude => latitude,
                                            :longitude => longitude,
                                            :physical_city => city,
                                            :physical_state =>
                                            fix_null_and_blank(l.state),
                                            :physical_zip => l.zipcode,
                                            :physical_country => country
                                            )

      # should do something here with primary locations?
      loc.save!
      current_org_stone.save!

      if (loc.longitude != nil and loc.latitude != nil)
        icon_group_id = current_org.icon_group_id

        SOLR_SEARCH::solr_update(solr_con,
                                 current_org_stone.id, loc.id,
                                 current_org_stone.name,
                                 org_types,
                                 icon_group_id,
                                 loc.longitude, loc.latitude,
                                 loc.physical_city,
                                 loc.physical_state,
                                 loc.physical_zip,
                                 loc.physical_country
                                 )
      end
      current_org_stone.ferret_update      
    end
  end

  solr_con.commit
end

