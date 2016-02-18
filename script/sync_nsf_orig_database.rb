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

  type_tags = {}
  NSF_DB::Type.all.each do |t|
    ot = OrgType.new(:name => t.type_name, :description => t.type_name)
    ot.save!
    org_tag = Tag.new(:root=> ot, :name => t.type_name )
    org_tag.save!
    type_tags[t.tid] = org_tag
  end

  current_org = nil
  current_org_stone = nil
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
    if current_org == nil or o.oid != current_org.oid
      current_org = o
      current_org_stone = Organization.new(:name => current_org.name)
      current_org_stone.set_access_rule(AccessRule::ACCESS_TYPE_PUBLIC)
      o.types.each do |org_type|
        current_org_stone.tags << type_tags[org_type.tid]
      end
      current_org_stone.save!
      orig_key_save = StoneToSolidarity.new(:stoneid=>current_org_stone.id,
                                            :solidarityid=>current_org.oid)
      orig_key_save.save!
    end

    # there are only 24 entries without city, StoneSoup requires one
    city = fix_null_and_blank(l.city)
    if city != nil
      loc = current_org_stone.locations.new(:note => l.location_name,
                                            :physical_address1 =>
                                            fix_null_and_blank(l.address),
                                            :physical_address2 =>
                                            fix_null_and_blank(l.address2),
                                            :latitude => nil,
                                            :longitude => nil,
                                            :physical_city => city,
                                            :physical_state =>
                                            fix_null_and_blank(l.state),
                                            :physical_zip => l.zipcode,
                                            :physical_country => l.country
                                            )

      # should do something here with primary locations?
      loc.save!
      current_org_stone.save!

      if (loc.longitude != nil and loc.latitude != nil)
        primary_type_name = nil
        if current_org_stone.tags.length >= 1
          primary_type_name = current_org_stone.tags[0].name
        end
        icon_group_id = nil
        if current_org.icon_groups.length >= 1
          icon_group_id = current_org.icon_groups[0].id
        end
        SOLR_SEARCH::solr_update(current_org_stone.id, loc.id,
                                 current_org_stone.name,
                                 primary_type_name,
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
end

