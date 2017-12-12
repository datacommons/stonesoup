require 'ostruct'


module OrganizationsHelper

  def summary(orgs)
    orgs = orgs.sort_by{ |x| x[:updated_at] or Time.now - 1000.years }.reverse
    locs, primary = summary_locations(orgs)
    phone, email, website = summary_contacts(orgs)
    tags = summary_tags(orgs)
    OpenStruct.new(:name => summary_name(orgs),
                   :description => summary_description(orgs),
                   :updated_at => nil,
                   :verified_dsos => [],
                   :locations => locs,
                   :primary_location => primary,
                   :products_services => [],
                   :tags => [],
                   :phone => phone,
                   :email => email,
                   :website => website,
                   :orgs => orgs,
                   :tags => tags
                   )
  end

  def summary_name(orgs)
    titles = orgs.map { |x| x.name }
    uppers = titles.map{ |x| x.gsub(/[^A-Z]/, '').length }
    mu = uppers.inject{ |sum, el| sum + el }.to_f / uppers.size
    lowers = titles.zip(uppers).select{ |t, ct| ct < mu * 1.25 }
    titles, uppers = lowers.transpose
    mu = uppers.inject{ |sum, el| sum + el }.to_f / lowers.size
    vals = uppers.map{ |x| (x - mu).abs }
    results = vals.zip(titles).sort
    results[0][1]
  end

  def summary_description(orgs)
    descs = orgs.map { |x| x.description or "" }
    lens = descs.map { |x| -x.length }
    lens.zip(descs).sort[0][1]
  end

  def summary_locations(orgs)
    good_location = false
    locations = []
    primary_location = nil
    for org in orgs
      if not good_location
        use_location = primary_location.blank?
        if org.primary_location
          if not org.primary_location.physical_state.blank?
            good_location = true
            use_location = true
          end
        end
        if use_location
          primary_location = org.primary_location
          locations = org.locations
        end
      end
    end
    return locations, primary_location
  end

  def prefer_site(v1, v2)
    return v1 if v2.blank?
    return v2 if v1.blank?
    if v2.include? '.coop' and !v1.include? '.coop'
      return v2
    end
    v1
  end

  def summary_contacts(orgs)
    phone = nil
    email = nil
    website = nil
    for org in orgs
      phone = org.phone if phone.blank?
      email = prefer_site(email, org.email)
      website = prefer_site(website, org.website)
    end
    return phone, email, website
  end

  def summary_tags(orgs)
    keys = {}
    tags = []
    for org in orgs
      for tag in org.tags
        parent = ""
        parent = tag.effective_parent.readable_name if tag.effective_parent
        key = "#{parent} -- #{tag.root_id} / #{tag.root_type}"
        unless keys.include? key
          tags << tag
          keys[key] = 1
        end
      end
    end
    tags
  end

end
