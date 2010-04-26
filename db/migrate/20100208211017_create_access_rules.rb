class CreateAccessRules < ActiveRecord::Migration
  def self.up
    create_table :access_rules do |t|
      t.string :access_type
    end
    add_column :organizations, :access_rule_id, :integer, :null => false
    add_column :people, :access_rule_id, :integer, :null => false
  end

  def self.down
    drop_table :access_rules
    remove_column :organizations, :access_rule_id
    remove_column :people, :access_rule_id
  end
end
