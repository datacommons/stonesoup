class Entry < ActiveRecord::Base
  has_and_belongs_to_many :users
  belongs_to :member
end

class MoveDataToNewDbSchema < ActiveRecord::Migration
  def self.up
    # new tables have already been created
    # new records have already been created in appropriate tables (i.e. org_types, legal_structures, etc.)
    # go through all Entries records
    Entry.find(:all).each do |entry|
      # create default AccessRule record (public)
      ar = AccessRule.new(:access_type => AccessRule::ACCESS_TYPE_PUBLIC)
      ar.save(false)  # don't validate
      
      # create Organization and other related records based on this Entry
      org = Organization.new(:name => entry.name,
        :description => entry.description,
        :created_at => entry.created_at,
        :created_by_id => entry.created_by_id,
        :updated_at => entry.updated_at,
        :updated_by_id => entry.updated_by_id,
        :phone => [entry.phone1, entry.phone2].collect{|p| (p || '').strip}.reject{|p| p.blank?}.join(', '),
        :fax => entry.fax,
        :email => entry.email,
        :website => entry.website,
        :year_founded => entry.year_founded,
        :democratic => entry.democratic,
        :access_rule_id => ar.id)
      org.save(false) # don't validate
      
      # create Location record
      loc = Location.new(:organization_id => org.id,
#        :note => 'default',  # Not populating "note" field for this location
        :physical_address1 => entry.physical_address1,
        :physical_address2 => entry.physical_address2,
        :physical_city => entry.physical_city,
        :physical_state => entry.physical_state,
        :physical_zip => entry.physical_zip,
        :physical_country => entry.physical_country,
        :mailing_address1 => entry.mailing_address1,
        :mailing_address2 => entry.mailing_address2,
        :mailing_city => entry.mailing_city,
        :mailing_state => entry.mailing_state,
        :mailing_zip => entry.mailing_zip,
        :mailing_country => entry.mailing_country,
        :latitude => entry.latitude,
        :longitude => entry.longitude,
        :created_at => entry.created_at,
        :updated_at => entry.updated_at)
      loc.save(false) # don't validate
      org.primary_location_id = loc.id  # set organization's primary location
      org.save(false)

      # TODONT: create Person record, link to Org, include link to relevant User(s)
      #NOTE: No person information available in old Entries table
      
      # create & link products_services records
      [entry.prod_serv1, entry.prod_serv2, entry.prod_serv3].each do |prodserv|
        next if prodserv.blank? # don't bother if it's blank
        ps = ProductService.new(:name => prodserv, :organization_id => org.id, :created_at => entry.created_at, :updated_at => entry.updated_at)
        ps.save(false)  #don't validate
      end
      
      ##### link related records as relevant #####
      
      # link Org to appropriate legal_structure
      structs = []
      structs.push 'Non-profit Corporation' if entry.non_profit_org
      structs.push 'Informal' if entry.informal
      structs.push 'Cooperative' if entry.cooperative
      structs.push 'Partnership' if entry.partnership
      structs.push 'Limited Liability Corporation (LLC)' if entry.llc
      structs.push 'S Corp' if entry.s_corporation
      structs.push 'C Corp' if entry.c_corporation
      structs.push '501(c)3' if entry.non_profit_corporation_501c3
      structs.push '501(c)4' if entry.non_profit_corporation_501c4
      if(structs.length > 1)
        msg = "ERROR: Flagging for review: Entry(#{entry.id})/Organization(#{org.id}) #{org.name} has multiple Legal Structures: #{structs.join(', ')}. Using #{structs[0]} for new Organization record."
        RAILS_DEFAULT_LOGGER.error(msg)
        puts msg
      end
      if(structs.length > 0)
        org.legal_structure_id = LegalStructure.find_by_name(structs[0]).id
        org.save(false)
      end
      
      # TODONT: link Org to appropriate member_orgs
      #NOTE: old Entries table has no data for these fields, don't bother migrating
      #union_association	tinyint(1)	YES		NULL	
      #which_union	varchar(255)	YES		NULL	
      
      # link Org to appropriate org_types
      org.org_types.push OrgType.find_by_name('Activist or Social Change Organization') if entry.activist_social_change_organization
      org.org_types.push OrgType.find_by_name('Community Currency or Barter Group') if entry.alternative_currency
      org.org_types.push OrgType.find_by_name('Artist -Run/Owned Space') if entry.artist_run_center
      org.org_types.push OrgType.find_by_name('Collective') if entry.collective
      org.org_types.push OrgType.find_by_name('Community Center') if entry.community_center
      org.org_types.push OrgType.find_by_name('Community Development Financial Institution') if entry.community_development_financial_institution
      org.org_types.push OrgType.find_by_name('Community Land Trust') if entry.community_land_trust
      org.org_types.push OrgType.find_by_name('Conservation/Agricultural Land Trust') if entry.conservation_ag_land_trust
      org.org_types.push OrgType.find_by_name('Cooperative, Consumer') if entry.consumer_coop
      org.org_types.push OrgType.find_by_name('Cooperative, Financial') if entry.cooperative_financial_institution
      org.org_types.push OrgType.find_by_name('ESOP') if entry.esop
      org.org_types.push OrgType.find_by_name('Fair Trade Organization or Business') if entry.fair_trade_organization
      org.org_types.push OrgType.find_by_name('Government Agency/Department/Program') if entry.government
      org.org_types.push OrgType.find_by_name('Cooperative, Housing') if entry.housing_coop
      org.org_types.push OrgType.find_by_name('Intentional Community or Ecovillage') if entry.intentional_community
      org.org_types.push OrgType.find_by_name('Majority Owned ESOP') if entry.majority_owned_esop
      org.org_types.push OrgType.find_by_name('Cooperative, Marketing') if entry.marketing_coop
      org.org_types.push OrgType.find_by_name('Mutual-aid/Self-help Group') if entry.mutual_aid_self_help_group
      org.org_types.push OrgType.find_by_name('Network, Association or Coalition') if entry.network_association
      org.org_types.push OrgType.find_by_name('Cooperative, Producer') if entry.producer_coop
      org.org_types.push OrgType.find_by_name('Support Organization') if entry.support_organization
      org.org_types.push OrgType.find_by_name('Union or Other Labor Organization') if entry.union_labor_organization
      org.org_types.push OrgType.find_by_name('Cooperative, Worker') if entry.worker_coop
      org.save(false)
      
      # TODONT: link Org to appropriate sectors
      #NOTE: no sector information in old Entries table
      
      # create org/user record owner links
      entry.users.each do |u|
        org.users.push u
      end
      org.save(false)
    end
    
    # drop unused tables
    drop_table :members
    drop_table :entries_users
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("Past the point of no return!")
  end
end
