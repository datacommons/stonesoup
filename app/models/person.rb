class Person < ActiveRecord::Base
  belongs_to :access_rule
  has_many :organizations_people, :dependent => :destroy
  has_many :organizations, :through => :organizations_people
  has_one :user

  has_many :data_sharing_orgs_taggables, :as => :taggable
  has_many :data_sharing_orgs, :through => :data_sharing_orgs_taggables

  has_many :locations, :as => :taggable

  acts_as_reportable

  validates_presence_of :firstname

  acts_as_ferret(:fields => {
    :name => {:boost => 2.0, :store => :yes },
    :access_type => { :store => :yes }
  })

  def access_type
    self.access_rule.access_type
  end
  
  def Person.latest_changes(filters)
    joinSQL, condSQLs, condParams = Organization.all_join(filters)
    joinSQL = "LEFT JOIN organizations_people ON organizations_people.person_id = people.id INNER JOIN organizations ON organizations_people.organization_id = organizations.id #{joinSQL}"
    conditions = []
    conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
    Person.find(:all, :select => 'people.*, locations.latitude AS filtered_latitude, locations.longitude AS filtered_longitude', :conditions => conditions, :joins => joinSQL, :limit => 100, :order => 'people.updated_at DESC')
  end

  def name
    [firstname, lastname].compact.join(' ')
  end  

  def oname 
    "p" + name
  end

  #def locations
  #  organizations.map{|o| o.locations}.flatten
  #end
  
  def accessible?(current_user)
    return true if !current_user.nil? and current_user.is_admin? # admins can access everything
    return false if self.access_rule.nil?
    case self.access_rule.access_type
    when AccessRule::ACCESS_TYPE_PUBLIC # public data, always visible
      return true
    when AccessRule::ACCESS_TYPE_LOGGEDIN # only visible if the current user is logged in
      return true unless current_user.nil?
    when AccessRule::ACCESS_TYPE_PRIVATE  # only visible to the entry's editor(s)
      return true if self.user == current_user
    else
      throw "Unknown access type: '#{self.access_rule.access_type}'"
    end
    # if access was not grated above, it is denied by default
    return false
  end
  
  def set_access_rule(access_type)
    logger.debug("setting access rule for Person record to: #{access_type}")
    if self.access_rule.nil?
      self.access_rule = AccessRule.new(:access_type => access_type)
    else
      self.access_rule.access_type = access_type
    end
  end
  
  def link_name
    name
  end
  
  def link_hash
    {:controller => 'people', :action => 'show', :id => self.id}
  end

  def to_s
    self.name
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end 

  def primary_location
    nil
  end

  def primary_location_id
    0
  end

  def get_primary
    Location.get_primary_for(self)
  end

  def description
    organizations.collect{|o| [o.name]}.join(", ")
  end
end
