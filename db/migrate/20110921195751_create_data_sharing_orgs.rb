class CreateDataSharingOrgs < ActiveRecord::Migration
  def self.up
    create_table :data_sharing_orgs do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :data_sharing_orgs
  end
end
