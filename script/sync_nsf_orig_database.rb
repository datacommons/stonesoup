#!./script/runner

ActiveRecord::Base.logger = Logger.new(STDOUT) 

class NSFEntity < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :nsf_db
end

class Entity < NSFEntity
  set_table_name "ids_master_list"
  set_primary_key "uid"
  set_inheritance_column "rails_type"
end

Entity.all.each do |e|
  puts e.hqname
end

Organization.all.each do |o|
  puts o.name
end

