class AddEntriesFields < ActiveRecord::Migration
  def self.up
    add_column :entries, :prod_serv1, :string
    add_column :entries, :prod_serv2, :string
    add_column :entries, :prod_serv3, :string
    add_column :entries, :support_organization, :boolean
    add_column :entries, :worker_coop, :boolean
    add_column :entries, :producer_coop, :boolean
    add_column :entries, :marketing_coop, :boolean
    add_column :entries, :housing_coop, :boolean
    add_column :entries, :consumer_coop, :boolean
    add_column :entries, :community_land_trust, :boolean
    add_column :entries, :conservation_ag_land_trust, :boolean
    add_column :entries, :alternative_currency, :boolean
    add_column :entries, :intentional_community, :boolean
    add_column :entries, :collective, :boolean
    add_column :entries, :artist_run_center, :boolean
    add_column :entries, :community_center, :boolean
    add_column :entries, :community_development_financial_institution, :boolean
    add_column :entries, :cooperative_financial_institution, :boolean
    add_column :entries, :mutual_aid_self_help_group, :boolean
    add_column :entries, :activist_social_change_organization, :boolean
    add_column :entries, :union_labor_organization, :boolean
    add_column :entries, :government, :boolean
    add_column :entries, :fair_trade_organization, :boolean
    add_column :entries, :network_association, :boolean
    add_column :entries, :non_profit_org, :boolean
    add_column :entries, :esop, :boolean
    add_column :entries, :majority_owned_esop, :boolean
    add_column :entries, :percentage_owned, :boolean
    add_column :entries, :other, :boolean
    add_column :entries, :type_of_other, :string
    add_column :entries, :naics_code, :integer
    add_column :entries, :informal, :boolean
    add_column :entries, :cooperative, :boolean
    add_column :entries, :partnership, :boolean
    add_column :entries, :llc, :boolean
    add_column :entries, :s_corporation, :boolean
    add_column :entries, :c_corporation, :boolean
    add_column :entries, :non_profit_corporation_501c3, :boolean
    add_column :entries, :non_profit_corporation_501c4, :boolean
    add_column :entries, :non_profit_corporation_other, :boolean
    add_column :entries, :other_type_of_incorp, :boolean
    add_column :entries, :type_of_other_incorp, :string
    add_column :entries, :have_a_fiscal_sponsor, :boolean
    add_column :entries, :year_founded, :date
    add_column :entries, :democratic, :boolean
    add_column :entries, :union_association, :boolean
    add_column :entries, :which_union, :string
  end

  def self.down
    remove_column :entries, :prod_serv1
    remove_column :entries, :prod_serv2
    remove_column :entries, :prod_serv3
    remove_column :entries, :support_organization
    remove_column :entries, :worker_coop
    remove_column :entries, :producer_coop
    remove_column :entries, :marketing_coop
    remove_column :entries, :housing_coop
    remove_column :entries, :consumer_coop
    remove_column :entries, :community_land_trust
    remove_column :entries, :conservation_ag_land_trust
    remove_column :entries, :alternative_currency
    remove_column :entries, :intentional_community
    remove_column :entries, :collective
    remove_column :entries, :artist_run_center
    remove_column :entries, :community_center
    remove_column :entries, :community_development_financial_institution
    remove_column :entries, :cooperative_financial_institution
    remove_column :entries, :mutual_aid_self_help_group
    remove_column :entries, :activist_social_change_organization
    remove_column :entries, :union_labor_organization
    remove_column :entries, :government
    remove_column :entries, :fair_trade_organization
    remove_column :entries, :network_association
    remove_column :entries, :non_profit_org
    remove_column :entries, :esop
    remove_column :entries, :majority_owned_esop
    remove_column :entries, :percentage_owned
    remove_column :entries, :other
    remove_column :entries, :type_of_other
    remove_column :entries, :naics_code
    remove_column :entries, :informal
    remove_column :entries, :cooperative
    remove_column :entries, :partnership
    remove_column :entries, :llc
    remove_column :entries, :s_corporation
    remove_column :entries, :c_corporation
    remove_column :entries, :non_profit_corporation_501c3
    remove_column :entries, :non_profit_corporation_501c4
    remove_column :entries, :non_profit_corporation_other
    remove_column :entries, :other_type_of_incorp
    remove_column :entries, :type_of_other_incorp
    remove_column :entries, :have_a_fiscal_sponsor
    remove_column :entries, :year_founded
    remove_column :entries, :democratic
    remove_column :entries, :union_association
    remove_column :entries, :which_union
  end
end
