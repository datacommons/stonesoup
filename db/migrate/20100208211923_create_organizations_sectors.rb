class CreateOrganizationsSectors < ActiveRecord::Migration
  def self.up
    create_table :organizations_sectors, :id => false do |t|
      t.integer :organization_id, :null => false
      t.integer :sector_id, :null => false
    end
  end

  def self.down
    drop_table :organizations_sectors
  end
end
