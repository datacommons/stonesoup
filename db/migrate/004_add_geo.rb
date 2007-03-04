class AddGeo < ActiveRecord::Migration
  def self.up
    add_column :entries, :latitude, :float 
    add_column :entries, :longitude, :float 
    add_column :entries, :distance, :float 
  end

  def self.down
    remove_column :entries, :latitude
    remove_column :entries, :longitude
    remove_column :entries, :distance
  end
end
