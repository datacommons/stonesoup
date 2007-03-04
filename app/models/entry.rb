class Entry < ActiveRecord::Base
  include Searchable
  include GeoKit::Geocoders

  has_and_belongs_to_many :users

  index_path "#{RAILS_ROOT}/db/entry_index"
  
  index_attr :name, :boost => 2.0
  index_attr :description

  def before_save
    address = "#{self.physical_address1},#{self.physical_address2},#{self.physical_city},#{self.physical_state},#{self.physical_zip},#{self.physical_country}"
    location=GoogleGeocoder.geocode(address)
    coords = location.ll.scan(/[0-9\.\-\+]+/)
    if coords.length == 2
      self.longitude = coords[1]
      self.latitude = coords[0]
    else
      self.longitude = "0"
      self.latitude = "0"
    end
  end

end
