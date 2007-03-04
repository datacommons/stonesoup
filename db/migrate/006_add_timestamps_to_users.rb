class AddTimestampsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :created_at, :datetime
    add_column :users, :last_login, :datetime
  end

  def self.down
    remove_column :users, :created_at
    remove_column :users, :last_login
  end
end
