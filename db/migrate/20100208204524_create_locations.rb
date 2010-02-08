class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.integer :organization_id, :null => false
      t.string :note
      t.string :physical_address1
      t.string :physical_address2
      t.string :physical_city
      t.string :physical_state
      t.string :physical_zip
      t.string :physical_country
      t.string :mailing_address1
      t.string :mailing_address2
      t.string :mailing_city
      t.string :mailing_state
      t.string :mailing_zip
      t.string :mailing_country
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end

  def self.down
    drop_table :locations
  end
end
