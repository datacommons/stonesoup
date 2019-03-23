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

ActiveRecord::Schema.define(:version => 0) do

  create_table "access_rules", :force => true do |t|
    t.text "access_type"
  end

  add_index "access_rules", ["id"], :name => "ix_access_rules_87ea5dfc8b8e384d"

  create_table "data_sharing_orgs", :force => true do |t|
    t.text "name"
  end

  add_index "data_sharing_orgs", ["name"], :name => "ix_data_sharing_orgs_6ae999552a0d2dca"

  create_table "data_sharing_orgs_taggables", :force => true do |t|
    t.text    "dso"
    t.text    "dso_update"
    t.integer "data_sharing_org_id"
    t.integer "foreign_key_id"
    t.integer "taggable_id"
    t.text    "taggable_type"
    t.integer "verified"
  end

  add_index "data_sharing_orgs_taggables", ["data_sharing_org_id", "taggable_id", "taggable_type"], :name => "ix_data_sharing_orgs_taggables_90868c357657838e"

  create_table "locations", :force => true do |t|
    t.text     "mailing_address1"
    t.text     "mailing_address2"
    t.text     "mailing_city"
    t.text     "mailing_state"
    t.text     "mailing_zip"
    t.text     "mailing_country"
    t.text     "mailing_county"
    t.text     "physical_county"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "note"
    t.text     "dso"
    t.text     "dso_update"
    t.text     "physical_zip"
    t.text     "taggable_type"
    t.text     "dccid"
    t.text     "physical_address1"
    t.float    "latitude"
    t.float    "longitude"
    t.text     "physical_country"
    t.integer  "taggable_id"
    t.text     "physical_city"
    t.text     "physical_address2"
    t.text     "physical_state"
  end

  add_index "locations", ["dccid"], :name => "ix_locations_1d6d94da1e93927d"

  create_table "oids", :force => true do |t|
    t.text "dccid"
    t.text "oid"
  end

  add_index "oids", ["dccid"], :name => "ix_oids_1d6d94da1e93927d"

  create_table "org_types", :force => true do |t|
    t.text "name"
  end

  create_table "organizations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "fax"
    t.text     "year_founded"
    t.text     "dso"
    t.text     "dso_update"
    t.text     "description"
    t.integer  "access_rule_id"
    t.text     "oid"
    t.text     "website"
    t.text     "name"
    t.text     "phone"
    t.text     "email"
    t.integer  "primary_location_id"
    t.text     "group"
    t.text     "grouping"
  end

  add_index "organizations", ["oid"], :name => "ix_organizations_2118c8699c550662"

  create_table "organizations_people", :force => true do |t|
    t.integer "person_id"
    t.integer "organization_id"
  end

  create_table "organizations_users", :force => true do |t|
    t.integer "user_id"
    t.integer "organization_id"
  end

  create_table "people", :force => true do |t|
    t.text "firstname"
    t.text "lastname"
  end

  create_table "product_services", :force => true do |t|
    t.text    "name"
    t.integer "organization_id"
  end

  create_table "tag_contexts", :force => true do |t|
    t.text "name"
    t.text "friendly_name"
  end

  add_index "tag_contexts", ["name"], :name => "ix_tag_contexts_6ae999552a0d2dca"

  create_table "taggings", :force => true do |t|
    t.text    "dso"
    t.text    "dso_update"
    t.integer "tag_id"
    t.integer "taggable_id"
    t.text    "taggable_type"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "ix_taggings_94bc7f962f82a803"

  create_table "tags", :force => true do |t|
    t.text    "root_type"
    t.integer "root_id"
    t.text    "name"
    t.integer "effective_id"
    t.integer "parent_id"
  end

  add_index "tags", ["root_id", "root_type"], :name => "ix_tags_c51485bf1a773cf3"

# Could not dump table "units" because of following StandardError
#   Unknown type '' for column 'taggable_id'

# Could not dump table "units_content" because of following StandardError
#   Unknown type '' for column 'c0taggable_id'

  create_table "units_docsize", :primary_key => "docid", :force => true do |t|
    t.binary "size"
  end

  create_table "units_segdir", :primary_key => "level", :force => true do |t|
    t.integer "idx"
    t.integer "start_block"
    t.integer "leaves_end_block"
    t.integer "end_block"
    t.binary  "root"
  end

  add_index "units_segdir", ["level", "idx"], :name => "sqlite_autoindex_units_segdir_1", :unique => true

  create_table "units_segments", :primary_key => "blockid", :force => true do |t|
    t.binary "block"
  end

  create_table "units_stat", :force => true do |t|
    t.binary "value"
  end

  create_table "users", :force => true do |t|
    t.text "login"
  end

end
