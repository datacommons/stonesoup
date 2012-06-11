class Location < ActiveRecord::Base
  # belongs_to :organization

  belongs_to :taggable, :polymorphic => true
  belongs_to :organization, :class_name => "Organization", :foreign_key => "taggable_id"
  belongs_to :person, :class_name => "Person", :foreign_key => "taggable_id"

  after_save :set_organizations_primary_location
  before_save :save_ll
  include LinkedRecordNotification
  
  include GeoKit::Geocoders

  acts_as_mappable :lat_column_name => 'latitude', 
                   :lng_column_name => 'longitude',
                   :distance_field_name => 'distance'

  validates_presence_of :taggable_id, :on => :save
  validates_each :physical_city, :physical_country do |record, attr, value|
    record.errors.add attr, "(or mailing city & country) must be specified" unless \
      (!record.physical_city.blank? and !record.physical_country.blank?) or \
      (!record.mailing_city.blank? and !record.mailing_country.blank?)
  end
  
  Location::ADDRESS_FIELDS = ['address1', 'address2', 'city', 'state', 'zip', 'county', 'country']
  Location::MODIFIED_ADDRESS_FIELDS = ['address1', 'address2', 'city', 'state_zip', 'county', 'country']
  Location::STATES = ['Alabama', 'Alaska', 'American Samoa', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'District of Columbia', 'Florida', 'Georgia', 'Guam', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Northern Marianas Islands', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Puerto Rico', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Virgin Islands', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming']
  Location::COUNTRY = ['United States', 'Canada']

  Location::COUNTRY_SHORT = {
    'USA' => 'United States',
    'CA' => 'Canada'
  }

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
    return unless taggable_type == "Organization"
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
    logger.debug("Geocoding: #{address} gives #{coords}")
    if coords.length == 2
      self.longitude = coords[1]
      self.latitude = coords[0]
    else
      self.longitude = nil
      self.latitude = nil
    end
    true
  rescue Exception => e
    true
  end
  
  def Location.get_primary_for(location, field = nil)
    primary = 'physical'  # default
    # find which address (physical or mailing) has the most complete info
    # first check for address1
    unless location.physical_address1.blank?
      primary = 'physical'
    else
      unless location.mailing_address1.blank?
        primary = 'mailing'
      else
        # if address1 is blank for both, check city
        unless location.physical_city.blank?
          primary = 'physical'
        else
          primary = 'mailing'
        end
      end
    end
    return primary
  end

  def get_primary(field = nil)
    Location.get_primary_for(self,field)
  end
  
  def to_s
    primary = get_primary
    return MODIFIED_ADDRESS_FIELDS.reject{|f| f=='county'}.collect{|f| self.send(primary+'_'+f)}.reject{|x| x==""}.join(', ')
  end

  def physical_state_zip
    return [physical_state, physical_zip].collect.join(' ')
  end

  def mailing_state_zip
    return [mailing_state, mailing_zip].collect.join(' ')
  end

  def accessible?(current_user)
    return self.taggable.accessible?(current_user)
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
    zip = blank_is_nil(physical_zip)
    unless zip
      zip = blank_is_nil(mailing_zip)
    end
    if zip
      return zip.gsub(/-.*/,'')
    end
    return nil
  end

  def summary_country
    country = blank_is_nil(physical_country)
    unless country
      country = blank_is_nil(mailing_country)
    end
    country
  end

  def summary_state
    state = blank_is_nil(physical_state)
    country = blank_is_nil(physical_country)
    unless state
      state = blank_is_nil(mailing_state)
      country = blank_is_nil(mailing_country)
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
    city = blank_is_nil(physical_city)
    unless city
      city = blank_is_nil(mailing_city)
    end
    return city
  end

  def blank_is_nil(x)
    if x
      if x.length==0
        x = nil
      end
    end
    return x
  end

  def name
    a = address_summary
    c = summary_city
    return c || "" if a.nil?
    return a if c.nil?
    a + " " + c
  end

  def link_name
    taggable.name + " (" + address_summary + ")"
  end
  
  def link_hash
    if taggable_type == "Organization"
      {:controller => 'organizations', :action => 'show', :id => organization.id}
    else
      {:controller => 'people', :action => 'show', :id => person.id}
    end
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end
end
