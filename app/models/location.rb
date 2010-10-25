class Location < ActiveRecord::Base
  belongs_to :organization

  include GeoKit::Geocoders

  acts_as_mappable :lat_column_name => 'latitude', 
                   :lng_column_name => 'longitude',
                   :distance_field_name => 'distance'

  validates_presence_of :organization_id
  validates_each :physical_city do |record, attr, value|
    record.errors.add attr, "and country or mailing city & country must be specified" unless \
      (!record.physical_city.blank? and !record.physical_country.blank?) or \
      (!record.mailing_city.blank? and !record.mailing_country.blank?)
#      
#      (record.physical_city.blank? and record.mailing_city.blank?) or \
#      (record.physical_country.blank? and record.mailing_country.blank?) or \
#      (record.physical_city.blank? and record.mailing_city.blank?)
  end
  
  Location::ADDRESS_FIELDS = ['address1', 'address2', 'city', 'state', 'zip', 'country']
  
  def mailing_address_blank?
    ADDRESS_FIELDS.each do |fld|
      return false unless self.send('mailing_'+fld).blank?
    end
  end
  
  def mailing_same_as_physical?
    ADDRESS_FIELDS.each do |fld|
      mail_field = self.send('mailing_' + fld)
      phys_field = self.send('physical_' + fld)
      return false if mail_field.blank? and !phys_field.blank? # if one is blank and the other is not, they're different
      # need to check that mail_field is not nil before doing a direct comparison
      return false if mail_field != phys_field
    end
    return true
  end
  
  def save_ll
    address = self.to_s
    location=GeoKit::Geocoders::GoogleGeocoder.geocode(address)
    coords = location.ll.scan(/[0-9\.\-\+]+/)
    if coords.length == 2
      self.longitude = coords[1]
      self.latitude = coords[0]
    else
      self.longitude = "0"
      self.latitude = "0"
    end
  end

  def to_s
    return "#{self.physical_address1},#{self.physical_address2},#{self.physical_city},#{self.physical_state},#{self.physical_zip},#{self.physical_country}"
  end

  def accessible?(current_user)
    return self.organization.accessible?(current_user)
  end

 def link_name
    organization.name + " (" + physical_address1 + ")"
  end
  
  def link_hash
    {:controller => 'organizations', :action => 'show', :id => organization.id}
  end
end
