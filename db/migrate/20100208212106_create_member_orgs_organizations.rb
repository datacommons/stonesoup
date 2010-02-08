class CreateMemberOrgsOrganizations < ActiveRecord::Migration
  def self.up
    create_table :member_orgs_organizations, :id => false do |t|
      t.integer :member_org_id, :null => false
      t.integer :organization_id, :null => false
    end
  end

  def self.down
    drop_table :member_orgs_organizations
  end
end
