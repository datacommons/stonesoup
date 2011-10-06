class AddForeignKeyIdToDataSharingOrgsOrganization < ActiveRecord::Migration
  def self.up
    add_column :data_sharing_orgs_organizations, :foreign_key_id, :string
    add_index :data_sharing_orgs_organizations, [:data_sharing_org_id, :foreign_key_id], :name => "dsoo_dso_fk", :unique => true
  end

  def self.down
    remove_index :data_sharing_orgs_organizations, :name => "dsoo_dso_fk"
    remove_column :data_sharing_orgs_organizations, :foreign_key_id
  end
end
