class Location < ActiveRecord::Base
  belongs_to :organization
  after_save :set_organizations_primary_location
  
  include GeoKit::Geocoders

  acts_as_mappable :lat_column_name => 'latitude', 
                   :lng_column_name => 'longitude',
                   :distance_field_name => 'distance'

  validates_presence_of :organization_id
  validates_each :physical_city do |record, attr, value|
    record.errors.add attr, "and country or mailing city & country must be specified" unless \
      (!record.physical_city.blank? and !record.physical_country.blank?) or \
      (!record.mailing_city.blank? and !record.mailing_country.blank?)
  end
  
  Location::ADDRESS_FIELDS = ['address1', 'address2', 'city', 'state', 'zip', 'county', 'country']
  Location::STATES = ['Alabama', 'Alaska', 'American Samoa', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'District of Columbia', 'Florida', 'Georgia', 'Guam', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Northern Marianas Islands', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Puerto Rico', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Virgin Islands', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming']

  Location::STATE_SHORT = {
    'AL' => 'Alabama',
    'AK' => 'Alaska',
    'AS' => 'America Samoa',
    'AZ' => 'Arizona',
    'AR' => 'Arkansas',
    'CA' => 'California',
    'CO' => 'Colorado',
    'CT' => 'Connecticut',
    'DE' => 'Delaware',
    'DC' => 'District of Columbia',
    'FM' => 'Micronesia',
    'FL' => 'Florida',
    'GA' => 'Georgia',
    'GU' => 'Guam',
    'HI' => 'Hawaii',
    'ID' => 'Idaho',
    'IL' => 'Illinois',
    'IN' => 'Indiana',
    'IA' => 'Iowa',
    'KS' => 'Kansas',
    'KY' => 'Kentucky',
    'LA' => 'Louisiana',
    'ME' => 'Maine',
    'MH' => 'Marshal Islands',
    'MD' => 'Maryland',
    'MA' => 'Massachusetts',
    'MI' => 'Michigan',
    'MN' => 'Minnesota',
    'MS' => 'Mississippi',
    'MO' => 'Missouri',
    'MT' => 'Montana',
    'NE' => 'Nebraska',
    'NV' => 'Nevada',
    'NH' => 'New Hampshire',
    'NJ' => 'New Jersey',
    'NM' => 'New Mexico',
    'NY' => 'New York',
    'NC' => 'North Carolina',
    'ND' => 'North Dakota',
    'OH' => 'Ohio',
    'OK' => 'Oklahoma',
    'OR' => 'Oregon',
    'PW' => 'Palau',
    'PA' => 'Pennsylvania',
    'PR' => 'Puerto Rico',
    'RI' => 'Rhode Island',
    'SC' => 'South Carolina',
    'SD' => 'South Dakota',
    'TN' => 'Tennessee',
    'TX' => 'Texas',
    'UT' => 'Utah',
    'VT' => 'Vermont',
    'VI' => 'Virgin Island',
    'VA' => 'Virginia',
    'WA' => 'Washington',
    'WV' => 'West Virginia',
    'WI' => 'Wisconsin',
    'WY' => 'Wyoming'
  }  

  def Location.unique_counties(state)
    pcs = Location.find(:all, :select => 'DISTINCT physical_county AS county', :conditions => ['physical_state = ?', state]).collect{|loc| loc.county}
    mcs = Location.find(:all, :select => 'DISTINCT mailing_county AS county', :conditions => ['mailing_state = ?', state]).collect{|loc| loc.county}
    (pcs + mcs).compact.sort
  end
  
  def set_organizations_primary_location
    if organization.primary_location.nil?  # if this is the first location added, assign it as the primary location
      organization.primary_location = self
      organization.send(:update_without_callbacks)
    end
  end
  
  def physical_address_blank?
    ADDRESS_FIELDS.each do |fld|
      return false unless self.send('physical_'+fld).blank?
    end
  end
  
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
  
  def get_primary(field = nil)
    primary = 'physical'  # default
    # find which address (physical or mailing) has the most complete info
    # first check for address1
    unless physical_address1.blank?
      primary = 'physical'
    else
      unless mailing_address1.blank?
        primary = 'mailing'
      else
        # if address1 is blank for both, check city
        unless physical_city.blank?
          primary = 'physical'
        else
          primary = 'mailing'
        end
      end
    end
    return primary
  end
  
  def to_s
    primary = get_primary
    #return "#{self.physical_address1},#{self.physical_address2},#{self.physical_city},#{self.physical_state},#{self.physical_zip},#{self.physical_country}"
    return ADDRESS_FIELDS.reject{|f| f=='county'}.collect{|f| self.send(primary+'_'+f)}.join(',')
  end

  def accessible?(current_user)
    return self.organization.accessible?(current_user)
  end

  def address_summary
    unless physical_address1.blank?
      addr = physical_address1 
    else
      unless mailing_address1.blank?
        addr = mailing_address1 
      else
        addr = ''
      end
    end
    addr
  end

  def summary_zip
    zip = nil
    if physical_zip
      if physical_zip.length>0
        zip = physical_zip
      end
    end
    unless zip
      if mailing_zip
        if mailing_zip.length>0
          zip = mailing_zip
        end
      end
    end
    if zip
      return zip.gsub(/-.*/,'')
    end
    return nil
  end

  def summary_state
    state = physical_state
    country = physical_country
    unless state
      state = mailing_state
      country = mailing_country
    end
    unless state
      return nil
    end
    alt = STATE_SHORT[state]
    if alt
      return alt
    end
    return state
  end

  def summary_city
    city = physical_city
    unless city
      city = mailing_city
    end
    return city
  end

  def link_name
    organization.name + " (" + address_summary + ")"
  end
  
  def link_hash
    {:controller => 'organizations', :action => 'show', :id => organization.id}
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end
end
