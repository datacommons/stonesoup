class AddCountyToLocations < ActiveRecord::Migration
  def self.up
    add_column :locations, :mailing_county, :string
    add_column :locations, :physical_county, :string
  end

  def self.down
    remove_column :locations, :mailing_county
    remove_column :locations, :physical_county
  end
end
