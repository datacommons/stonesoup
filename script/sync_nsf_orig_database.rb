#!./script/runner

require 'nsf_db'
require 'solr_update'

#ActiveRecord::Base.logger = Logger.new(STDOUT) 

# from import_helper, should be done with require
def fix_null_and_blank(a)
  if a == "NULL" or a == ""
    nil
  else
    a
  end
end

#dso = DataSharingOrg.find(1) # NSF_US_solidarity DSO

org_tag = nil
current_org = nil
# assumption, all branches have the same type...
# do testing for that outside using sql
# select distinct(oid) from ids_master_list;
# select distinct(oid,type) from ids_master_list;
#
# that assumption, combined with having an index on type,oid,uid allows us
# to go through this table in one pass
#
# for now we're loading everything to memory, ideally would re-code for less
# but non-int id column is making that difficult with the support active_record
# has for that
NSF_DB::Entity.all(:order => "type,oid,uid").each do |e|
  if org_tag == nil or org_tag.name != e.org_type
    ot = OrgType.new(:name => e.org_type, :description => e.org_type)
    ot.save!
    org_tag = Tag.new(:root=> ot, :name => e.org_type )
    org_tag.save!
  end

  if current_org == nil or e.id != current_org.id
    current_org = Organization.new(:name => e.hqname
                                   )
    current_org.set_access_rule(AccessRule::ACCESS_TYPE_PUBLIC)
    current_org.tags << org_tag

    current_org.save!

    #DataSharingOrgsTaggable.linked_org_to_dso(current_org, dso, nil)

    #current_org.save!
    #dso.save!

  end

  city = fix_null_and_blank(e.city)
  if city != nil
    loc = current_org.locations.new(:note => e.branch_name,
                                    :physical_address1 =>
                                    fix_null_and_blank(e.address),
                                    :latitude => nil,
                                    :longitude => nil,
                                    :physical_city => city,
                                    :physical_state =>
                                    fix_null_and_blank(e.state),
                                    :physical_zip => nil,
                                    :physical_country => "United States"
                                    )
    # no postal code in imported db ?
    # note we're not doing anything with e.comments
    loc.save!
    current_org.save!

    if (loc.longitude != nil and loc.latitude != nil)
      SOLR_SEARCH::solr_update(current_org.id, loc.id, current_org.name,
                               loc.longitude, loc.latitude)
    end
  end

  # for some reason, the DSO link doesn't seem to "take" for
  # ferret purposes - reload
  #current_org = Organization.find(current_org.id)

  current_org.ferret_update
end

# make a tag and organization type for each type of organization
# and build an in-memory index of these tags
#org_type_tags = {}
#NSF_DB::Entity.all(:select => "DISTINCT(type)").each do |e|
#  
  #ot.save!
#  t = Tag.new(:root=> ot, :name => e.org_type )
  #t.save!
#  org_type_tags[e.org_type] = t
#end

#NSF_DB::Entity.find_each do |e|
#  
#end


#Organization.all.each do |o|
#  puts o.name
#end

