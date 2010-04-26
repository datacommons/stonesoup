class CreateMemberOrgs < ActiveRecord::Migration
  def self.up
    create_table :member_orgs do |t|
      t.text :name
      t.boolean :custom

      t.timestamps
    end
    MemberOrg.new(:name => 'U.S. Federation of Worker Coops-Worker Coop', :custom => false).save!
    MemberOrg.new(:name => 'U.S. Federation of Worker Coops-Other Democratic Workplace', :custom => false).save!
    MemberOrg.new(:name => 'U.S. Federation of Worker Coops-Associate', :custom => false).save!
    MemberOrg.new(:name => 'U.S. Federation of Worker Coops-Individual', :custom => false).save!
    MemberOrg.new(:name => 'U.S. Federation of Worker Coops-Developer', :custom => false).save!
    MemberOrg.new(:name => 'NASCO', :custom => false).save!
    MemberOrg.new(:name => 'U.S. Solidarity Economy Network', :custom => false).save!
    MemberOrg.new(:name => 'National Cooperative Business Association', :custom => false).save!
  end

  def self.down
    drop_table :member_orgs
  end
end
