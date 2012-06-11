class PeopleCanHaveLocationsToo < ActiveRecord::Migration
  def self.up
    add_column :locations, :taggable_type, :string, :default => "Organization"
    rename_column :locations, :organization_id, :taggable_id
  end

  def self.down
    rename_column :locations, :taggable_id, :organization_id
    remove_column :locations, :taggable_type
  end
end
