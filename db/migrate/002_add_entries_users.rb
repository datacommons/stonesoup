class AddEntriesUsers < ActiveRecord::Migration
  def self.up
    create_table :entries_users, :id => false do |t|
      t.column :entry_id, :integer
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :entries_users
  end
end
