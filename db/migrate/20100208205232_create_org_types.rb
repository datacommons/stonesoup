class CreateOrgTypes < ActiveRecord::Migration
  def self.up
    create_table :org_types do |t|
      t.string :name
      t.text :description
      t.boolean :custom

      t.timestamps
    end
    OrgType.new(:name => 'Academic Institution or Program', :description => 'Any organization, program or project that is administered or orgnanized through an academic institution', :custom => false).save!
    OrgType.new(:name => 'Activist or Social Change Organization', :description => 'This field is self-defined', :custom => false).save!
    OrgType.new(:name => 'Artist -Run/Owned Space', :description => 'A space, gallery, store or center focusing on the arts that is owned/rented and controlled by the artists whose work is present', :custom => false).save!
    OrgType.new(:name => 'Collective', :description => 'A group organized for a common purpose  in which all members share decision-making power.', :custom => false).save!
    OrgType.new(:name => 'Community Center', :description => 'A space for community gathering/use that is owned/rented and controlled by the community that uses it', :custom => false).save!
    OrgType.new(:name => 'Community Currency or Barter Group', :description => 'A group organized to facilitate exchange of goods and services without the use of national, government-issued currency', :custom => false).save!
    OrgType.new(:name => 'Community Development Credit Union', :custom => false).save!
    OrgType.new(:name => 'Community Development Financial Institution', :description => 'Private-sector financial institution with community development as its primary mission', :custom => false).save!
    OrgType.new(:name => 'Community Garden Project', :custom => false).save!
    OrgType.new(:name => 'Community Land Trust', :custom => false).save!
    OrgType.new(:name => 'Community Supported Agriculture (CSA) Program', :custom => false).save!
    OrgType.new(:name => 'Community-Building Group', :custom => false).save!
    OrgType.new(:name => 'Conservation/Agricultural Land Trust', :description => 'A non-profit organization dedicated to holding land and/or easements for the purposes of conserving its ecological and/or agricultural integrity', :custom => false).save!
    OrgType.new(:name => 'Conventional Business', :custom => false).save!
    OrgType.new(:name => 'Conventional Non-Profit', :custom => false).save!
    OrgType.new(:name => 'Cooperative, Consumer', :description => 'Member-owned and democratically-controlled association though which consumers collectively purchase and distribute goods/services', :custom => false).save!
    OrgType.new(:name => 'Cooperative, Financial', :description => 'A financial institution that is a cooperative', :custom => false).save!
    OrgType.new(:name => 'Cooperative, Housing', :description => 'Multi-family/unit housing that is owned and democratically controlled by its residents', :custom => false).save!
    OrgType.new(:name => 'Cooperative, Marketing', :custom => false).save!
    OrgType.new(:name => 'Cooperative, Multi-Stakeholder', :custom => false).save!
    OrgType.new(:name => 'Cooperative, Producer', :description => 'Producer owned and democratically- controlled organization that serves its members (who may or may not be themselves cooperatives) through cooperative marketing, support and/or purchasing', :custom => false).save!
    OrgType.new(:name => 'Cooperative, Retail', :custom => false).save!
    OrgType.new(:name => 'Cooperative, Worker', :description => 'A business that is owned and democratically controlled by its workers/employees', :custom => false).save!
    OrgType.new(:name => 'Credit Union', :description => 'A financial institution that is owned and controlled by its members', :custom => false).save!
    OrgType.new(:name => 'ESOP', :description => 'Employee Stock Ownership Program', :custom => false).save!
    OrgType.new(:name => 'Fair Trade Organization or Business', :custom => false).save!
    OrgType.new(:name => 'Financial Institution Supporting Cooperatives', :custom => false).save!
    OrgType.new(:name => 'Government Agency/Department/Program', :description => 'Any organization or agency that is administered by or through a local, state or national government body', :custom => false).save!
    OrgType.new(:name => 'Intentional Community or Ecovillage', :custom => false).save!
    OrgType.new(:name => 'Majority Owned ESOP', :description => 'ESOP in which 51% or more of stock is owned by workers', :custom => false).save!
    OrgType.new(:name => 'Mutual-aid/Self-help Group', :description => 'A group or organization that is dedicated to building and maintaining relationships of mutual aid and support between and among its members', :custom => false).save!
    OrgType.new(:name => 'Network, Association or Coalition', :custom => false).save!
    OrgType.new(:name => 'Other Cooperative Financial Institution', :description => 'A financial institution that is owned and controlled by its members, but is not a credit union', :custom => false).save!
    OrgType.new(:name => 'Support Organization', :description => 'Organization that provides services, resources or any form of support to cooperative/solidarity economy initiatives or enterprises', :custom => false).save!
    OrgType.new(:name => 'Union or Other Labor Organization', :custom => false).save!
  end

  def self.down
    drop_table :org_types
  end
end
