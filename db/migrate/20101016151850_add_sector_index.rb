class AddSectorIndex < ActiveRecord::Migration
  def self.up
    add_index :organizations_sectors, :organization_id
    add_index :organizations_sectors, :sector_id
  end

  def self.down
    remove_index :organizations_sectors, :organization_id
    remove_index :organizations_sectors, :sector_id
  end
end
