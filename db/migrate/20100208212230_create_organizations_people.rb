class CreateOrganizationsPeople < ActiveRecord::Migration
  def self.up
    create_table :organizations_people do |t|
      t.integer :organization_id, :null => false
      t.integer :person_id, :null => false
      t.string :role_name
      t.string :phone
      t.string :email
      t.timestamps
    end
  end

  def self.down
    drop_table :organizations_people
  end
end
