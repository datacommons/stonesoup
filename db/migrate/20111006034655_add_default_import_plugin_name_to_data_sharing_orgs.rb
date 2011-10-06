class AddDefaultImportPluginNameToDataSharingOrgs < ActiveRecord::Migration
  def self.up
    add_column :data_sharing_orgs, :default_import_plugin_name, :string
  end

  def self.down
    remove_column :data_sharing_orgs, :default_import_plugin_name
  end
end
