class CreateSectors < ActiveRecord::Migration
  def self.up
    create_table :sectors do |t|
      t.string :name

      t.timestamps
    end
    Sector.new(:name => 'Academic/Education').save!
    Sector.new(:name => 'Accomodation & Food Services').save!
    Sector.new(:name => 'Arts & Culture').save!
    Sector.new(:name => 'Childcare').save!
    Sector.new(:name => 'Community & Economic Development').save!
    Sector.new(:name => 'Community-Building & Mutual Aid').save!
    Sector.new(:name => 'Construction & Repair').save!
    Sector.new(:name => 'Farm, Fish & Forest').save!
    Sector.new(:name => 'Farm, Fish & Forest_Animal Production').save!
    Sector.new(:name => 'Farm, Fish & Forest_Crop Production').save!
    Sector.new(:name => 'Farm, Fish & Forest_Fishing, Hunting & Trapping').save!
    Sector.new(:name => 'Farm, Fish & Forest_Forestry & Logging').save!
    Sector.new(:name => 'Finance & Insurance').save!
    Sector.new(:name => 'Government & Public Administration').save!
    Sector.new(:name => 'Healthcare').save!
    Sector.new(:name => 'Housing & Land').save!
    Sector.new(:name => 'Information Technology').save!
    Sector.new(:name => 'Labor Organization').save!
    Sector.new(:name => 'Legal Services').save!
    Sector.new(:name => 'Manufacturing').save!
    Sector.new(:name => 'Manufacturing_Fabricated Metals').save!
    Sector.new(:name => 'Manufacturing_Food & Beverage Production').save!
    Sector.new(:name => 'Manufacturing_Furniture').save!
    Sector.new(:name => 'Manufacturing_Machinery, Computers, Electronics, & Electrical Equipment').save!
    Sector.new(:name => 'Manufacturing_Other').save!
    Sector.new(:name => 'Manufacturing_Petroleum, Coal, Chemicals, Plastics, Minerals & Metals').save!
    Sector.new(:name => 'Manufacturing_Printing').save!
    Sector.new(:name => 'Manufacturing_Textiles, Apparel & Leather').save!
    Sector.new(:name => 'Manufacturing_Transportation Equipment').save!
    Sector.new(:name => 'Manufacturing_Wood & Paper').save!
    Sector.new(:name => 'Media').save!
    Sector.new(:name => 'Mining').save!
    Sector.new(:name => 'Network, Coalition, or Association').save!
    Sector.new(:name => 'Organizational Support & Development').save!
    Sector.new(:name => 'Personal Care & Cleaning Services').save!
    Sector.new(:name => 'Private Household').save!
    Sector.new(:name => 'Religious or Spiritual').save!
    Sector.new(:name => 'Retail Trade').save!
    Sector.new(:name => 'Retail Trade_Books, Music & Hobby Supplies').save!
    Sector.new(:name => 'Retail Trade_Clothing & Accessories').save!
    Sector.new(:name => 'Retail Trade_Food, Beverages & Health Supplies').save!
    Sector.new(:name => 'Retail Trade_Other').save!
    Sector.new(:name => 'Retail Trade_Vehicles, Furniture, Electronics, Tools & Equipment').save!
    Sector.new(:name => 'Social Change Organization').save!
    Sector.new(:name => 'Social Services').save!
    Sector.new(:name => 'Transportation & Warehousing').save!
    Sector.new(:name => 'Utilities').save!
    Sector.new(:name => 'Waste Management & Remediation').save!
    Sector.new(:name => 'Wholesale Trade').save!
  end

  def self.down
    drop_table :sectors
  end
end
