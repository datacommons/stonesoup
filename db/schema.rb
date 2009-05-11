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

ActiveRecord::Schema.define(:version => 7) do

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

  create_table "entries_users", :id => false, :force => true do |t|
    t.integer "entry_id"
    t.integer "user_id"
  end

  create_table "members", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "login",      :limit => 80
    t.string   "password",   :limit => 40
    t.boolean  "is_admin"
    t.integer  "member_id"
    t.datetime "created_at"
    t.datetime "last_login"
  end

end
