class UpdateUsersPeopleLink < ActiveRecord::Migration
  def self.up
    add_column :users, :person_id, :integer
    remove_column :users, :member_id
  end

  def self.down
    add_column :users, :member_id, :integer
    remove_column :users, :person_id
  end
end
