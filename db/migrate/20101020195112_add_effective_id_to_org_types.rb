class AddEffectiveIdToOrgTypes < ActiveRecord::Migration
  def self.up
    add_column :org_types, :effective_id, :integer
  end

  def self.down
    remove_column :org_types, :effective_id
  end
end
