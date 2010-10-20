class AddLocationOrgIndex < ActiveRecord::Migration
  def self.up
    add_index :locations, :organization_id
  end

  def self.down
    remove_index :locations, :organization_id
  end
end
