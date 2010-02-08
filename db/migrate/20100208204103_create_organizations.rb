class CreateOrganizations < ActiveRecord::Migration
  def self.up
    create_table :organizations do |t|
      t.string :name, :null => false
      t.text :description
      t.integer :created_by_id
      t.integer :updated_by_id
      t.string :phone
      t.string :fax
      t.string :email
      t.string :website
      t.date :year_founded
      t.boolean :democratic
      t.integer :primary_location_id

      t.timestamps
    end
  end

  def self.down
    drop_table :organizations
  end
end
