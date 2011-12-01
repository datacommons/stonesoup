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
    a.downcase.gsub(/[^a-z0-9]/,'')
  end

  def loose_match(a,b)
    simplify(a) == simplify(b)
  end

  def match_with_ferret_base(org_attr, loc_attr, dso)
    errors = []
    match_status = {}
    orgs = []

    orgName = org_attr[:name]
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


  def match_with_ferret(org_attr, loc_attr, dso)
    match_with_ferret_base(org_attr, loc_attr, dso)
    orgName = org_attr[:name]
    entry = {}
    if @orgs.length == 0
      errors.push "No matches for #{orgName}"
      entry['stub'] = org_attr
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


  def apply(dso, default_access_type, action, org_attr, loc_attr)
    if action == :add

      organization = Organization.new(org_attr)
      organization.set_access_rule(default_access_type)
      organization.save!

      DataSharingOrgsOrganization.linked_org_to_dso(organization, dso, nil)

      loc = organization.locations.new(loc_attr)
      loc.save!

      # for some reason, the DSO link doesn't seem to "take" for
      # ferret purposes - reload
      organization = Organization.find(organization.id)

      organization.ferret_update
      return organization
    end
    return match_with_ferret(org_attr, loc_attr, dso)
  end

end
