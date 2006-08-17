class Entry < ActiveRecord::Base
  include Searchable

  index_path "#{RAILS_ROOT}/db/entry_index"
  
  index_attr :name, :boost => 2.0
  index_attr :description

end
