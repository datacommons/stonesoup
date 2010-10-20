class AddProductServiceOrgIndex < ActiveRecord::Migration
  def self.up
    add_index :product_services, :organization_id
  end

  def self.down
    remove_index :product_services, :organization_id
  end
end
