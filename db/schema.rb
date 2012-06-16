# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120611021937) do

  create_table "access_rules", :force => true do |t|
    t.string "access_type"
  end

  create_table "data_sharing_orgs", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "default_import_plugin_name"
  end

  create_table "data_sharing_orgs_taggables", :force => true do |t|
    t.integer  "data_sharing_org_id",                             :null => false
    t.integer  "taggable_id",                                     :null => false
    t.boolean  "verified",            :default => false,          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "foreign_key_id"
    t.string   "taggable_type",       :default => "Organization"
  end

  add_index "data_sharing_orgs_taggables", ["data_sharing_org_id", "foreign_key_id"], :name => "dsoo_dso_fk", :unique => true

  create_table "data_sharing_orgs_users", :id => false, :force => true do |t|
    t.integer  "data_sharing_org_id", :null => false
    t.integer  "user_id",             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "entries", :force => true do |t|
    t.string   "name"
    t.string   "physical_address1"
    t.string   "physical_address2"
    t.string   "physical_city"
    t.string   "physical_state"
    t.string   "physical_zip"
    t.string   "physical_country"
    t.string   "mailing_address1"
    t.string   "mailing_address2"
    t.string   "mailing_city"
    t.string   "mailing_state"
    t.string   "mailing_zip"
    t.string   "mailing_country"
    t.string   "phone1"
    t.string   "phone2"
    t.string   "fax"
    t.string   "email"
    t.string   "website"
    t.string   "preferred_contact"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.float    "latitude"
    t.float    "longitude"
    t.float    "distance"
    t.integer  "member_id"
    t.string   "prod_serv1"
    t.string   "prod_serv2"
    t.string   "prod_serv3"
    t.boolean  "support_organization"
    t.boolean  "worker_coop"
    t.boolean  "producer_coop"
    t.boolean  "marketing_coop"
    t.boolean  "housing_coop"
    t.boolean  "consumer_coop"
    t.boolean  "community_land_trust"
    t.boolean  "conservation_ag_land_trust"
    t.boolean  "alternative_currency"
    t.boolean  "intentional_community"
    t.boolean  "collective"
    t.boolean  "artist_run_center"
    t.boolean  "community_center"
    t.boolean  "community_development_financial_institution"
    t.boolean  "cooperative_financial_institution"
    t.boolean  "mutual_aid_self_help_group"
    t.boolean  "activist_social_change_organization"
    t.boolean  "union_labor_organization"
    t.boolean  "government"
    t.boolean  "fair_trade_organization"
    t.boolean  "network_association"
    t.boolean  "non_profit_org"
    t.boolean  "esop"
    t.boolean  "majority_owned_esop"
    t.boolean  "percentage_owned"
    t.boolean  "other"
    t.string   "type_of_other"
    t.integer  "naics_code"
    t.boolean  "informal"
    t.boolean  "cooperative"
    t.boolean  "partnership"
    t.boolean  "llc"
    t.boolean  "s_corporation"
    t.boolean  "c_corporation"
    t.boolean  "non_profit_corporation_501c3"
    t.boolean  "non_profit_corporation_501c4"
    t.boolean  "non_profit_corporation_other"
    t.boolean  "other_type_of_incorp"
    t.string   "type_of_other_incorp"
    t.boolean  "have_a_fiscal_sponsor"
    t.date     "year_founded"
    t.boolean  "democratic"
    t.boolean  "union_association"
    t.string   "which_union"
  end

  create_table "legal_structures", :force => true do |t|
    t.text     "name"
    t.boolean  "custom"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "locations", :force => true do |t|
    t.integer  "taggable_id",                                   :null => false
    t.string   "note"
    t.string   "physical_address1"
    t.string   "physical_address2"
    t.string   "physical_city"
    t.string   "physical_state"
    t.string   "physical_zip"
    t.string   "physical_country"
    t.string   "mailing_address1"
    t.string   "mailing_address2"
    t.string   "mailing_city"
    t.string   "mailing_state"
    t.string   "mailing_zip"
    t.string   "mailing_country"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mailing_county"
    t.string   "physical_county"
    t.string   "taggable_type",     :default => "Organization"
  end

  add_index "locations", ["taggable_id"], :name => "index_locations_on_organization_id"

  create_table "member_orgs", :force => true do |t|
    t.text     "name"
    t.boolean  "custom"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "effective_id"
  end

  create_table "member_orgs_organizations", :id => false, :force => true do |t|
    t.integer "member_org_id",   :null => false
    t.integer "organization_id", :null => false
  end

  create_table "org_types", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "custom"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "effective_id"
  end

  create_table "org_types_organizations", :id => false, :force => true do |t|
    t.integer "org_type_id",     :null => false
    t.integer "organization_id", :null => false
  end

  create_table "organizations", :force => true do |t|
    t.string   "name",                  :null => false
    t.text     "description"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "phone"
    t.string   "fax"
    t.string   "email"
    t.string   "website"
    t.date     "year_founded"
    t.boolean  "democratic"
    t.integer  "primary_location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "legal_structure_id"
    t.integer  "access_rule_id",        :null => false
    t.datetime "import_notice_sent_at"
    t.string   "email_response_token"
    t.datetime "responded_at"
    t.string   "response"
  end

  add_index "organizations", ["email_response_token"], :name => "index_organizations_on_email_response_token"

  create_table "organizations_people", :force => true do |t|
    t.integer  "organization_id", :null => false
    t.integer  "person_id",       :null => false
    t.string   "role_name"
    t.string   "phone"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "organizations_people", ["organization_id"], :name => "index_organizations_people_on_organization_id"
  add_index "organizations_people", ["person_id"], :name => "index_organizations_people_on_person_id"

  create_table "organizations_sectors", :id => false, :force => true do |t|
    t.integer "organization_id", :null => false
    t.integer "sector_id",       :null => false
  end

  add_index "organizations_sectors", ["organization_id"], :name => "index_organizations_sectors_on_organization_id"
  add_index "organizations_sectors", ["sector_id"], :name => "index_organizations_sectors_on_sector_id"

  create_table "organizations_users", :id => false, :force => true do |t|
    t.integer  "organization_id", :null => false
    t.integer  "user_id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people", :force => true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "phone_mobile"
    t.string   "phone_home"
    t.string   "fax"
    t.string   "email"
    t.boolean  "phone_contact_preferred"
    t.boolean  "email_contact_preferred"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "access_rule_id",          :null => false
  end

  create_table "product_services", :force => true do |t|
    t.string   "name"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "product_services", ["organization_id"], :name => "index_product_services_on_organization_id"

  create_table "sectors", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tag_contexts", :force => true do |t|
    t.string "name"
    t.string "friendly_name"
  end

  add_index "tag_contexts", ["name"], :name => "index_tag_contexts_on_name"

  create_table "tag_worlds", :force => true do |t|
    t.string "name"
  end

  add_index "tag_worlds", ["name"], :name => "index_tag_worlds_on_name"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.integer  "root_id"
    t.string   "root_type"
    t.integer  "parent_id"
    t.integer  "effective_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"
  add_index "tags", ["parent_id"], :name => "index_tags_on_parent_id"
  add_index "tags", ["root_id", "root_type"], :name => "index_tags_on_root_id_and_root_type"

  create_table "users", :force => true do |t|
    t.string   "login",                        :limit => 80
    t.string   "password",                     :limit => 40
    t.boolean  "is_admin"
    t.datetime "created_at"
    t.datetime "last_login"
    t.integer  "person_id"
    t.boolean  "update_notifications_enabled",               :default => true
  end

end
