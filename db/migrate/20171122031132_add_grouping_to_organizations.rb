class AddGroupingToOrganizations < ActiveRecord::Migration
  def self.up
    add_column :organizations, :grouping, :string
  end

  def self.down
    remove_column :organizations, :grouping
  end
end
