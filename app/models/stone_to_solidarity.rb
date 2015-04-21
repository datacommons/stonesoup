# created manually with

#create table stone_to_solidarity (mapid serial primary key, stoneid int not null unique references organizations(id), solidarityid int unique);

class StoneToSolidarity < ActiveRecord::Base
  self.primary_key = "mapid"
  set_table_name "stone_to_solidarity"
  has_one :organization, :class_name => "Organization", :foreign_key => "stoneid", :primary_key => "id"
end
