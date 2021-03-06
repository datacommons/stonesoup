module NSF_DB
  class NSFEntity < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :nsf_db
  end

  class Organization < NSFEntity 
    has_many :locations, :foreign_key=> "oid"
    has_and_belongs_to_many :types,
      :join_table=> "org_and_type_assoc",
      :foreign_key=> "oid",
      :association_foreign_key=> "tid"

    has_one :icon_group, :foreign_key => "icon_group_id", :primary_key => "id"

    self.primary_key = "oid"
  end

  class Location < NSFEntity
    set_table_name "locations"
    set_primary_key "lid"
    has_one :organization, :foreign_key => "oid", :primary_key => "oid"
    #set_inheritance_column "rails_type"
  end

  class Type < NSFEntity
    self.primary_key = "tid"
    has_and_belongs_to_many :organizations,
      :join_table=> "org_and_type_assoc",
      :foreign_key=> "tid",
      :association_foreign_key=> "oid"
  end

  class IconGroup < NSFEntity
    set_table_name "icon_groups"
    self.primary_key = "id"
  end

  class Suggestion < NSFEntity
    set_table_name "suggestions"
    self.primary_key = "id"
  end

end
