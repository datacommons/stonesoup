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
  has_many :data_sharing_orgs_organizations, :dependent => :destroy
  has_many :data_sharing_orgs, :through => :data_sharing_orgs_organizations
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'

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
                   :access_type => { :store => :yes },
                   :verified => { :via => :verified_to_s },
                   :city => { :via => :cities_to_s },
#                   :public => { :store => :yes },
                   :pool => { :via => :pool_to_s },
                 } )

  acts_as_reportable

  validates_presence_of :name

  before_save :record_acting_user
  before_update :save_old_values
  after_update :send_notifications
  after_save :save_access_rule
  
  UPDATE_NOTIFICATION_IGNORED_COLUMNS = ['id', 'created_at', 'created_by_id', 'updated_at', 'updated_by_id']
  UPDATE_NOTIFICATION_HAS_ONE_COLUMNS = ['legal_structure', 'access_rule']
  #UPDATE_NOTIFICATION_INCLUDED_ASSOCIATIONS = ['locations', 'products_services', 'org_types', 'sectors', 'member_orgs', 'organizations_people', 'users', 'legal_structure', 'access_rule']
  
  def save_access_rule
    self.access_rule.save unless self.access_rule.nil?
  end
  
  def reset_email_response_token!
    # first generate a token and make sure it's unique
    token = nil
    while(token.nil? or Organization.find_by_email_response_token(token))
      token = Common::random_token
    end
    # set it on the org record and save
    self.email_response_token = token
    self.save!
  end
  
  def record_acting_user
    return unless User.current_user  # should never happen, but lets check just in case
    if self.new_record?
      self.created_by_id = User.current_user.id
    else
      self.updated_by_id = User.current_user.id
    end
  end
  
  def verified_to_s
    verified_dsos.any? ? 'yes' : 'no'
  end
  
  def verified_dsos
    self.data_sharing_orgs_organizations.select{|link| link.verified}.map{|link| link.data_sharing_org}
  end

  def get_value_hash
    oldvalues = Hash[*self.class.columns.reject{|c| UPDATE_NOTIFICATION_IGNORED_COLUMNS.include?(c.name)}.collect {|c| [c.name, self.send(c.name)]}.flatten]
    UPDATE_NOTIFICATION_HAS_ONE_COLUMNS.each do |hasone|
      unless self.respond_to?(hasone)
        logger.error("ERROR: Organization has no method '#{hasone}' -- please update Organization::UPDATE_NOTIFICATION_HAS_ONE_COLUMNS")
        next
      end
      oldvalues.delete(hasone + '_id')
      value = self.send(hasone)
      oldvalues[hasone] = value.to_s unless value.nil?
    end
    #logger.debug("returning value_hash as : #{oldvalues.inspect}")
    return oldvalues
  end
  
  def save_old_values
    org = self.class.find(self.id)
    @oldvalues = org.get_value_hash
    #logger.debug("#{self.class}#save_old_values: Saving @oldvalues=#{@oldvalues.inspect}")
    return true
  end
  
  def send_notifications
    newvalues = self.get_value_hash
    
    changes_hash = Common::changes_hash(@oldvalues, newvalues)
    if changes_hash.empty?
      logger.debug("No changes to report")
      return true
    end

    logger.debug("sending update notification for: #{self.name} (##{self.id})")
    
    change_message = "Organization record updated:\n"
    changes_hash.each do |change|
      change_message += "* #{change[:field]} changed "
      if(change[:from].match(/\n/) or change[:to].match(/\n/))  # if either contains a newline, use separate lines from from/to
        change_message += "---- from: --------------------------\n"
        change_message += change[:from] + "\n"
        change_message += "---- to: --------------------------\n"
        change_message += change[:to] + "\n"
      else
        change_message += "from #{change[:from]} to #{change[:to]}\n"
      end
    end
    
    # send notifications to all the other editors on this entry, except the person making the update
    self.users.reject{|u| u == User.current_user}.each do |user|
      next unless user.update_notifications_enabled?  # skip if notifications are disabled
      Email.deliver_update_notification(user, self, change_message)
    end
    
    # if this record is part of a DSO's data set, AND the acting user is NOT a "trusted" user
    # send a notification to that DSO
    if self.data_sharing_orgs.any? and !self.trust_user?(User.current_user)
      self.data_sharing_orgs.each do |dso|
        # set the entry's status to "unverified"
        DataSharingOrgsOrganization.set_status(dso, self, false)

        # send a notification to that DSO
        Email.deliver_dso_update_notification(dso, self, change_message)
      end
    end
    
    return true
  end
  
  def trust_user?(user)
    # if the org is part of a DSO's data pool
    # and the user is an editor for that DSO
    # then they are trusted
    if self.data_sharing_orgs.collect(&:users).flatten.include?(user)
      return true
    end
    
    # other "trusted user" criteria
    #TODO
    #BONUS: DSO feature "trust pre-existing editors" with a timeframe (e.g. 5 minutes, 1 day, etc.).  So if a DSO approves a record, and that record is later modified by a pre-existing editor of that record, approval should be unaffected.
    #- notify the DSO of the change in any case (and offer stricter, less trusting options)
    #- use the timestamp on that association (the "created_at" field in the organizations_users table) to determine "pre-existing editor" status
    
    return false
  end
  
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
    self.locations.collect{|loc| [loc.physical_state, loc.mailing_state, loc.summary_state]}.compact.uniq.join(', ')
  end
  
  def cities_to_s
    self.locations.collect{|loc| [loc.physical_city, loc.mailing_city, loc.summary_city]}.compact.uniq.join(', ')
  end
  
  def zips_to_s
    self.locations.collect{|loc| [loc.physical_zip, loc.mailing_zip, loc.summary_zip]}.compact.uniq.join(', ')
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

  def pool_to_s
    self.data_sharing_orgs.collect{|dso| dso.to_s}.join(', ')
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
  
  def Organization.latest_changes(state_filter = [], city_filter = [], zip_filter = [], dso_filter = [], org_type_filter = [])
    user = User.current_user
    conditions = nil
    condSQLs = []
    condParams = []
    joinSQL = 'INNER JOIN locations ON locations.organization_id = organizations.id'
    unless state_filter.nil? or state_filter.empty?
      logger.debug("applying session state filters to search results: #{state_filter.inspect}")
      states = [state_filter].flatten
      condSQLs << "(locations.physical_state IN (#{states.collect{'?'}.join(',')})) OR (locations.mailing_state IN (#{states.collect{'?'}.join(',')}))"
      condParams += states + states
    end

    unless city_filter.nil? or city_filter.empty?
      logger.debug("applying session city filters to search results: #{city_filter.inspect}")
      cities = [city_filter].flatten
      condSQLs << "(locations.physical_city IN (#{cities.collect{'?'}.join(',')})) OR (locations.mailing_city IN (#{cities.collect{'?'}.join(',')}))"
      condParams += cities + cities
    end

    unless zip_filter.nil? or zip_filter.empty?
      logger.debug("applying session zip filters to search results: #{zip_filter.inspect}")
      zips = [zip_filter].flatten.collect{|x| x.sub('*','%')}
      zip_str = zips.collect{|z| "(locations.physical_zip LIKE ?)"}.join(" OR ")
      # condSQLs << "(locations.physical_zip IN (#{cities.collect{'?'}.join(',')})) OR (locations.mailing_zip IN (#{cities.collect{'?'}.join(',')}))"
      condSQLs << zip_str
      condParams += zips
    end

    unless dso_filter.nil? or dso_filter.empty?
      logger.debug("applying session dso filters to search results: #{dso_filter.inspect}")
      joinSQL = "#{joinSQL} INNER JOIN data_sharing_orgs_organizations ON data_sharing_orgs_organizations.organization_id = organizations.id INNER JOIN data_sharing_orgs ON data_sharing_orgs_organizations.data_sharing_org_id = data_sharing_orgs.id"
      dsos = [dso_filter].flatten
      condSQLs << "data_sharing_orgs.name IN (#{dsos.collect{'?'}.join(',')})"
      condParams += dsos
    end

    unless org_type_filter.nil? or org_type_filter.empty?
      logger.debug("applying session org_type filters to search results: #{org_type_filter.inspect}")
      joinSQL = "#{joinSQL} INNER JOIN org_types_organizations ON org_types_organizations.organization_id = organizations.id INNER JOIN org_types ON org_types_organizations.org_type_id = org_types.id"
      org_types = [org_type_filter].flatten
      condSQLs << "org_types.name IN (#{org_types.collect{'?'}.join(',')})"
      condParams += org_types
    end

    conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
    logger.debug("After applying filters, conditions = #{conditions.inspect}")

    Organization.find(:all, :select => 'organizations.*, locations.latitude AS filtered_latitude, locations.longitude AS filtered_longitude', :order => 'organizations.updated_at DESC', 
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

  def to_s
    self.name
  end

  def to_xml(options = {})
    options[:include] ||= :locations
    super(options)
  end

  def to_json(options)
    options[:include] ||= :locations
    super(options)
  end


end
