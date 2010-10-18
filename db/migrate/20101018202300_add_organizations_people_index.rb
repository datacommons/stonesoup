class AddOrganizationsPeopleIndex < ActiveRecord::Migration
  def self.up
    add_index :organizations_people, :organization_id
    add_index :organizations_people, :person_id
  end

  def self.down
    remove_index :organizations_people, :organization_id
    remove_index :organizations_people, :person_id
  end
end
