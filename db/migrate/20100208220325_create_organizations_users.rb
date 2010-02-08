class CreateOrganizationsUsers < ActiveRecord::Migration
  def self.up
    create_table :organizations_users, :id=> false do |t|
      t.integer :organization_id, :null => false
      t.integer :user_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :organizations_users
  end
end
