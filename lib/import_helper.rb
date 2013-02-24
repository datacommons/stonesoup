require 'active_support/core_ext/string'
require 'proto_entry'

class ImportHelper
  attr_accessor :errors, :match_status, :orgs, :match

  def fix_null(a)
    if a == "NULL"
      nil
    else
      a
    end
  end

  def simplify(a)
    return a if a.nil?
    a.downcase.gsub(/[^a-z0-9]/,'')
  end

  def loose_match(a,b)
    simplify(a) == simplify(b)
  end

  def match_with_ferret_base(org_attr, loc_attr, dso)
    errors = []
    match_status = {}
    orgs = []

    orgName = org_attr[:name] || "NOTHINGTOSEEHEARMOVEALONGFOLKS"
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
      unless seek_name.include? " "
        match_status[:weak] = true
      end
      if orgs.length>1
        orgs = []
        break
      end
    end
    match = nil
    if orgs.nil?
      errors.push "Do not know what to do with #{orgName}"
    elsif orgs.length == 1
      match = orgs.first
      match_status[:linked] = match.data_sharing_orgs.member? dso
      unless match_status[:linked]
        if match_status[:weak]
          plausible = false
          match.locations.each do |loc|
            if loose_match(loc.summary_city,loc_attr[:physical_city])
              plausible = true
            end
            addr = ""
            x = loc.physical_address1
            unless x.nil?
              unless x.gsub(/[^A-Za-z0-9]/,'').length>0
                x = nil
              end
            end
            unless x.nil?
              addr = loc.physical_address1 unless loc.physical_address1.nil?
              addr = addr + " " + loc.physical_address2 unless loc.physical_address2.nil?
            else
              addr = loc.mailing_address1 unless loc.mailing_address1.nil?
              addr = addr + " " + loc.mailing_address2 unless loc.mailing_address2.nil?
            end
            if loose_match(addr,loc_attr[:physical_address1])
              plausible = true
            end
          end
          unless plausible
            errors.push "Implausible location match for #{orgName}"
            match = nil
            orgs = []
          end
        end
      end
    end

    @errors = errors
    @match_status = match_status
    @orgs = orgs
    @match = match
  end


  def match_with_ferret(org_attr, loc_attr, dso, entry)
    match_with_ferret_base(org_attr, loc_attr, dso)
    orgName = org_attr[:name]
    if @orgs.length == 0
      errors.push "No matches for #{orgName}"
      entry['stub'] = org_attr
      entry['location_stub'] = loc_attr
      @match_status[:available] = true
    else
      errors.push "Many matches for #{orgName}"
      @match_status[:ambiguous] = true
    end
    entry['name'] = orgName
    entry['summary_text'] = loc_attr[:physical_address1].to_s + " " + loc_attr[:physical_city].to_s + " " + loc_attr[:physical_state].to_s  + " / " + org_attr[:website].to_s

    return {:errors => @errors, :record_status => :processed, 
      :local => entry,
      :remote => @match,
      :match_status => @match_status
    }
  end


  def apply(dso, default_access_type, action, org_attr, loc_attr, entry)
    if action == :add

      organization = Organization.new(org_attr)
      organization.set_access_rule(default_access_type)
      organization.save!

      DataSharingOrgsTaggable.linked_org_to_dso(organization, dso, nil)

      loc = organization.locations.new(loc_attr)
      loc.save!

      # for some reason, the DSO link doesn't seem to "take" for
      # ferret purposes - reload
      organization = Organization.find(organization.id)

      organization.ferret_update
      return organization
    end
    return match_with_ferret(org_attr, loc_attr, dso, entry)
  end


  def apply_proto(dso, action, proto)
    RAILS_DEFAULT_LOGGER.debug("IMPORT: basics dso #{dso.inspect}         action #{action.inspect}             proto #{proto.inspect}")
    if action == :add
      return add(dso,proto)
    end
    return apply(dso,proto.default_access_type,action,proto.org_attr,
                 proto.location_attrs[0], 
                 proto.entry)
  end

  def add(dso,proto)
    RAILS_DEFAULT_LOGGER.debug("IMPORT: here I am!")
    errors = []
    default_access_type = proto.default_access_type

    organization = Organization.new(proto.org_attr)
    organization.set_access_rule(default_access_type)
    organization.save!
    
    RAILS_DEFAULT_LOGGER.debug("IMPORT: working on org #{proto.tags}")
    need_save = false
    if proto.tags
      proto.tags.each do |name|
        tag = nil
        if name.kind_of?(Array)
          parent = Tag.find_by_name(name[0])
          tag = Tag.find_by_name_and_parent_id(name[1],parent.id) if parent
        else
          tag = Tag.find_by_name(name)
        end
        organization.tags.push(tag) if tag
        RAILS_DEFAULT_LOGGER.debug("IMPORT: added tag #{tag.inspect}") if tag
      end
    end

    if need_save
      organization.save!
    end

    DataSharingOrgsTaggable.linked_org_to_dso(organization, dso, nil)

    # now process org_type_names, loading or creating as necessary...
    organization.org_types = proto.org_type_names.collect{|name| OrgType.find_or_create_custom(name.strip)} if proto.org_type_names
    

    # process legal structure, loading or creating as necessary
    unless(proto.legal_structure_name.blank?)
      RAILS_DEFAULT_LOGGER.debug("IMPORT: setting org's legal_structure to: #{proto.legal_structure_name}")
      organization.legal_structure = LegalStructure.find_or_create_custom(proto.legal_structure_name.strip)
    end

    if proto.sector_names
      # process sectors: find/link or report error
      organization.sectors = []
      RAILS_DEFAULT_LOGGER.debug("IMPORT: setting org's sectors to: #{proto.sector_names.inspect}")
      proto.sector_names.each do |sector_name|
        ## sector_name = SECTOR_MAP[sector_name] unless SECTOR_MAP[sector_name].nil? # if there's a mapped value, use it
        sector = Sector.find_by_name(sector_name.strip)
        if(sector.nil?)
          msg = "Sector not found for '#{sector_name}' - import value should be updated to match existing selections or new Sector must be added by Admin."
          RAILS_DEFAULT_LOGGER.error('IMPORT: ' + msg)
          errors.push(msg)
        else
          organization.sectors.push(sector)
        end
      end
    end
    
    if proto.member_orgs
      # link in member orgs, if any
      current_member_org_names = organization.member_orgs.map(&:name).sort
      new_member_org_names = proto.member_orgs.map(&:name).sort
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
    end

    if proto.product_service_names
      # link in products/services, if new/changed
      current_ps_names = organization.products_services.map(&:name)
      if(current_ps_names.sort != proto.product_service_names.sort)
        # lists are different, need to update...
        RAILS_DEFAULT_LOGGER.debug("IMPORT: Current PS names: #{current_ps_names.inspect}")
        RAILS_DEFAULT_LOGGER.debug("IMPORT: New PS names: #{proto.product_service_names.inspect}")
        # first, remove any now missing
        organization.products_services.each do |ps|
          unless proto.product_service_names.include?(ps.name)
            RAILS_DEFAULT_LOGGER.debug("IMPORT: Removing Product/Service: #{ps.name}")
            ps.destroy
          end
        end
        # next, add any new ones
        proto.product_service_names.each do |ps_name|
          unless(current_ps_names.include?(ps_name))
            RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding Product/Service: #{ps_name}")
            ps = organization.products_services.find_or_create_by_name(:name => ps_name)
            ps.save!
          end
        end
        RAILS_DEFAULT_LOGGER.debug("IMPORT: After update, new PS names: #{organization.products_services.map(&:name).inspect}")
      end
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
      # -- PF adds -- but destroying people could be a disaster, they
      # can be in other organizations too ...
      organization.people.destroy_all
    end
    if proto.contact_attrs
      proto.contact_attrs.each do |c|
        contact1_attr = c[:person_attr]
        contact1_link_attr = c[:link_attr]
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
      end
    end

    if proto.tags
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
      proto.location_attrs.each do |loc_attr|
        loc_attr[:physical_country] = 'United States' unless loc_attr[:physical_state].blank?
        loc_attr[:mailing_country] = 'United States' unless loc_attr[:mailing_state].blank?
        loc = organization.locations.new(loc_attr)
        if(loc.valid?)
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Adding Location to organization: #{loc.physical_address1} / #{loc.physical_city}")
          loc.save!
        else
          RAILS_DEFAULT_LOGGER.debug("IMPORT: Location is invalid: #{loc.errors.full_messages.inspect}")
        end
      end
    end

    return organization
  end

  
end
