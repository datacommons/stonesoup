class RemoveSynonymAndCustomFields < ActiveRecord::Migration
  def self.up
    remove_column :legal_structures, :custom
    remove_column :member_orgs, :custom
    remove_column :member_orgs, :effective_id
    remove_column :org_types, :custom
    remove_column :org_types, :effective_id
  end

  def self.down
    add_column :legal_structures, :custom, :boolean
    add_column :member_orgs, :custom, :boolean
    add_column :member_orgs, :effective_id, :integer
    add_column :org_types, :custom, :boolean
    add_column :org_types, :effective_id, :integer
  end
end
