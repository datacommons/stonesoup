class AddEffectiveIdToMemberOrgs < ActiveRecord::Migration
  def self.up
    add_column :member_orgs, :effective_id, :integer
  end

  def self.down
    remove_column :member_orgs, :effective_id
  end
end
