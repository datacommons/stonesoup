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

  acts_as_ferret(:fields => {
                   :name => {:boost => 2.0, :store => :yes },
                   :description => { :store => :yes },
                   :products_services_to_s => { :store => :yes },
                   :location => { :via => :locations_to_s,
                     :store => :yes },
                   # some different tags to enable more selective searches
                   :state => { :via => :states_to_s },
                   :zip => { :via => :zips_to_s },
                   :country => { :via => :countries_to_s },
                   :sector => { :via => :sectors_to_s },
                   :org_type => { :via => :org_types_to_s },
                   :access_type => { :store => :yes }
#                   :public => { :store => :yes },
                 } )

  acts_as_reportable

  validates_presence_of :name

  before_save :save_ll
  
  def get_org_types
    org_types.collect{|ot| ot.root_term}.uniq
  end
  
  def get_member_orgs
    member_orgs.collect{|mo| mo.root_term}.uniq
  end
  
  def access_type
    self.access_rule.access_type
  end
  
  def products_services_to_s
    self.products_services.collect{|ps| ps.name}.join(', ')
  end

  def locations_to_s
    self.locations.collect{|loc| loc.to_s}.join(', ')
  end
  
  def states_to_s
    self.locations.collect{|loc| [loc.physical_state, loc.mailing_state]}.compact.uniq.join(', ')
  end
  
  def zips_to_s
    self.locations.collect{|loc| loc.physical_zip}.uniq.join(', ')
  end
  
  def countries_to_s
    self.locations.collect{|loc| [loc.physical_country, loc.mailing_country]}.compact.uniq.join(', ')
  end
  
  def sectors_to_s
    self.sectors.collect{|sect| sect.name}.join(', ')
  end
  
  def org_types_to_s
    self.org_types.collect{|org_type| org_type.name}.join(', ')
  end
  
  def set_access_rule(access_type)
    if self.access_rule.nil?
      self.access_rule = AccessRule.new(:access_type => access_type)
    else
      self.access_rule.access_type = access_type
    end
  end
  
  def accessible?(current_user)
    return true if !current_user.nil? and current_user.is_admin? # admins can access everything
    return false if self.access_rule.nil?
    case self.access_rule.access_type
    when AccessRule::ACCESS_TYPE_PUBLIC # public data, always visible
      return true
    when AccessRule::ACCESS_TYPE_LOGGEDIN # only visible if the current user is logged in
      return true unless current_user.nil?
    when AccessRule::ACCESS_TYPE_PRIVATE  # only visible to the entry's editor(s)
      return true if self.users.include?(current_user)
    else
      throw "Unknown access type: '#{self.access_rule.access_type}'"
    end
    # if access was not grated above, it is denied by default
    return false
  end
  
  def public
    self.access_rule.access_type == AccessRule::ACCESS_TYPE_PUBLIC
  end
  
  def longitude
    if self.primary_location
      self.primary_location.longitude
    else
      nil
    end
  end
  
  def latitude
    if self.primary_location
      self.primary_location.latitude
    else
      nil
    end
  end
  
  def save_ll
    self.locations.each do |loc|
      loc.save_ll
      loc.save(false)
    end
  end

  def Organization.latest_changes(state_filter = [])
    user = User.current_user
    conditions = nil
    unless state_filter.nil? or state_filter.empty?
      condSQLs = []
      condParams = []
      joinSQL = nil
      logger.debug("applying session state filters to search results: #{state_filter.inspect}")
      joinSQL = 'INNER JOIN locations ON locations.organization_id = organizations.id'
      states = [state_filter].flatten
      condSQLs << "(locations.physical_state IN (#{states.collect{'?'}.join(',')})) OR (locations.mailing_state IN (#{states.collect{'?'}.join(',')}))"
      condParams += states + states
      conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
      logger.debug("After applying state_filter, conditions = #{conditions.inspect}")
    end

    Organization.find(:all, :select => 'organizations.*', :order => 'updated_at DESC', 
               :limit => 15,
               :conditions => conditions,
               :joins => joinSQL)
  end
  
  def link_name
    name
  end
  
  def link_hash
    {:controller => 'organizations', :action => 'show', :id => self.id}
  end

end
