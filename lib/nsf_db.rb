module NSF_DB
  class NSFEntity < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :nsf_db
  end

  class Entity < NSFEntity
    set_table_name "ids_master_list"
    set_primary_key "uid"
    set_inheritance_column "rails_type"

    # because the type function is reserved by active record for
    # finding the class
    def org_type
      read_attribute("type")
    end
  end
end
