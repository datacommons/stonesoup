class LinkUsersToDsos < ActiveRecord::Migration
  def self.up
    create_table :data_sharing_orgs_users, :id => false do |t|
      t.integer :data_sharing_org_id, :null => false
      t.integer :user_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :data_sharing_orgs_users
  end
end
