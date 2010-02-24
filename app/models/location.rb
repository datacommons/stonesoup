class Location < ActiveRecord::Base
  belongs_to :organization
  
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
