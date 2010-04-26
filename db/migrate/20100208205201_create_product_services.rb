class CreateProductServices < ActiveRecord::Migration
  def self.up
    create_table :product_services do |t|
      t.string :name
      t.integer :organization_id

      t.timestamps
    end
  end

  def self.down
    drop_table :product_services
  end
end
