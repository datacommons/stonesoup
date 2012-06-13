class DsoizePeople < ActiveRecord::Migration
  def self.up
    rename_table :data_sharing_orgs_organizations, :data_sharing_orgs_taggables
    add_column :data_sharing_orgs_taggables, :taggable_type, :string, :default => "Organization"
    rename_column :data_sharing_orgs_taggables, :organization_id, :taggable_id
  end

  def self.down
    rename_column :data_sharing_orgs_taggables, :taggable_id, :organization_id
    remove_column :data_sharing_orgs_taggables, :taggable_type
    rename_table :data_sharing_orgs_taggables, :data_sharing_orgs_organizations
  end
end
