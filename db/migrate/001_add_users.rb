class AddUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column "login", :string, :limit => 80
      t.column "password", :string, :limit => 40
    end
  end

  def self.down
    drop_table :users
  end
end
