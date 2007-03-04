class AddMembers < ActiveRecord::Migration
  def self.up
    create_table :members do |t|
      t.column :name, :string
    end

    add_column :users, :member_id, :integer
    add_column :entries, :member_id, :integer
  end

  def self.down
    drop_table :members
    remove_column :users, :member_id
    remove_column :entries, :member_id
  end
end
