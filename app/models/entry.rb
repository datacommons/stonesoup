class Entry < ActiveRecord::Base
  include Searchable
  include GeoKit::Geocoders

  before_save :save_ll

  has_and_belongs_to_many :users
  belongs_to :member

  index_path "#{RAILS_ROOT}/db/entry_index"
  
  index_attr :name, :boost => 2.0
  index_attr :description
  index_attr :public
  index_attr :member_id

  def public
    member == nil
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

  def self.latest_changes
    user = User.current_user
    conditions = if user && user.is_admin?
                   nil
                 elsif user && user.member
                   ['member_id is NULL or member_id = ?', user.member.id]
                 else
                   ['member_id is NULL']
                 end

    Entry.find(:all, :order => 'updated_at DESC', 
               :limit => 15,
               :conditions => conditions)
  end

end
