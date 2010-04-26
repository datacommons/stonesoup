class CreateLegalStructures < ActiveRecord::Migration
  def self.up
    create_table :legal_structures do |t|
      t.text :name
      t.boolean :custom

      t.timestamps
    end
    LegalStructure.new(:name => 'Informal', :custom => false).save!
    LegalStructure.new(:name => 'Cooperative', :custom => false).save!
    LegalStructure.new(:name => 'Partnership', :custom => false).save!
    LegalStructure.new(:name => 'Limited Liability Corporation (LLC)', :custom => false).save!
    LegalStructure.new(:name => 'C Corp', :custom => false).save!
    LegalStructure.new(:name => 'S Corp', :custom => false).save! # NOTE: not in spreadsheet
    LegalStructure.new(:name => 'Non-profit Corporation', :custom => false).save!
    LegalStructure.new(:name => '501(c)3', :custom => false).save!
    LegalStructure.new(:name => '501(c)4', :custom => false).save!
    add_column :organizations, :legal_structure_id, :integer
  end

  def self.down
    drop_table :legal_structures
    remove_column :organizations, :legal_structure_id
  end
end
