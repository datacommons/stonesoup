class Entry < ActiveRecord::Base
  include Searchable

  has_and_belongs_to_many :users

  index_path "#{RAILS_ROOT}/db/entry_index"
  
  index_attr :name, :boost => 2.0
  index_attr :description

end
