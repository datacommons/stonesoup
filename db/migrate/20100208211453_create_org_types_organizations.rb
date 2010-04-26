class CreateOrgTypesOrganizations < ActiveRecord::Migration
  def self.up
    create_table :org_types_organizations, :id => false do |t|
      t.integer :org_type_id, :null => false
      t.integer :organization_id, :null => false
    end
  end

  def self.down
    drop_table :org_types_organizations
  end
end
