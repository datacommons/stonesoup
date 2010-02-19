class Organization < ActiveRecord::Base
  has_many :locations, :dependent => :destroy
  belongs_to :primary_location, :class_name => 'Location'
  has_many :products_services, :dependent => :destroy, :class_name => 'ProductService'
  belongs_to :legal_structure
  belongs_to :access_rule
  has_and_belongs_to_many :org_types
  has_and_belongs_to_many :sectors
  has_and_belongs_to_many :member_orgs
  has_many :organizations_people, :dependent => :destroy
  has_many :people, :through => :organizations_people
  has_and_belongs_to_many :users

  include GeoKit::Geocoders

#TODO
#  acts_as_ferret(:fields => {
#                   :name => {:boost => 2.0, :store => :yes },
#                   :description => { :store => :yes },
#                   :physical_zip => { :store => :yes },
#                   :public => { :store => :yes },
#                   :member_id => { :store => :yes }
#                 } )

  acts_as_mappable :lat_column_name => 'latitude', 
                   :lng_column_name => 'longitude',
                   :distance_field_name => 'distance'

  acts_as_reportable

  before_save :save_ll
  
  def public
    self.access_rule.access_type == AccessRule::ACCESS_TYPE_PUBLIC
  end
  
  def longitude
    self.primary_location.longitude
  end
  
  def latitude
    self.primary_location.latitude
  end
  
  def save_ll
    self.locations.each do |loc|
      loc.save_ll
      loc.save(false)
    end
  end

  def self.latest_changes
    user = User.current_user
    conditions = if user && user.is_admin?
                   nil
#TODO
#                 elsif user && user.member
#                   ['member_id is NULL or member_id = ?', user.member.id]
#                 else
#                   ['member_id is NULL']
                 end

    Organization.find(:all, :order => 'updated_at DESC', 
               :limit => 15,
               :conditions => conditions)
  end
  
	def create_address(attr)
		l = self.locations.create(attr)
		l.save!
		if self.locations.length == 1 then	# if this is the first address added, make it primary
			self.primary_location_id = l.id
			self.save(false)
		end
	end
end
