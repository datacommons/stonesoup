class LinkOrganizationsToDsos < ActiveRecord::Migration
  def self.up
    create_table :data_sharing_orgs_organizations do |t|
      t.integer :data_sharing_org_id, :null => false
      t.integer :organization_id, :null => false
      t.boolean :verified, :null => false, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :data_sharing_orgs_organizations
  end
end
