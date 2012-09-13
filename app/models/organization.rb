class Organization < ActiveRecord::Base

  # NOTE on object relationships:
  # DO NOT use [ :dependent => :destroy ] or [ :dependent => :delete_all ] 
  # as this removes the related objects BEFORE the before_destroy callback is processed for the object itself
  # (because we need to have the DSO relations intact to be able to notify the DSO of the removal)
  # those related objects are now destroyed in the after_destroy callback manually
  has_many :locations, :as => :taggable
  belongs_to :primary_location, :class_name => 'Location'
  has_many :products_services, :class_name => 'ProductService'
  belongs_to :legal_structure
  belongs_to :access_rule
  has_and_belongs_to_many :org_types
  has_and_belongs_to_many :sectors
  has_and_belongs_to_many :member_orgs
  has_many :organizations_people
  has_many :people, :through => :organizations_people
  has_and_belongs_to_many :users

  # has_many :data_sharing_orgs_organizations
  # has_many :data_sharing_orgs, :through => :data_sharing_orgs_organizations
  has_many :data_sharing_orgs_taggables, :as => :taggable
  has_many :data_sharing_orgs, :through => :data_sharing_orgs_taggables

  has_many :data_sharing_orgs_organizations, :class_name => "DataSharingOrgsTaggable", :as => :taggable, :conditions => "data_sharing_orgs_taggables.taggable_type = 'Organization'"

  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  has_many :tags, :through => :taggings
  has_many :taggings, :as => :taggable

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
  after_update :notify_changes
  after_save :save_access_rule
  before_destroy :notify_destroy
  attr_accessor :destruction_in_progress # flag to mark if the org is currently being deleted (for notification handling)
  after_destroy :destroy_related_objects
  def destroy_related_objects
    self.locations.destroy_all
    self.products_services.destroy_all
    self.data_sharing_orgs_organizations.destroy_all
    self.organizations_people.destroy_all
  end
  
  def Organization.update_notification_has_one_columns
    return ['legal_structure', 'access_rule']
  end
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
  
  def save_old_values
    org = self.class.find(self.id)
    @oldvalues = org.get_value_hash
    #logger.debug("#{self.class}#save_old_values: Saving @oldvalues=#{@oldvalues.inspect}")
    return true
  end
  
  def send_notifications(change_message, type = :update)
    return unless @organization # e.g. working from console

    # send notifications to all the other editors on this entry, except the person making the update
    other_editors = self.users.reject{|u| u == User.current_user}
    logger.debug("other editors on this entry: #{other_editors.collect{|u| u.login}.join(', ')}")
    other_editors.reject!{|u| !u.update_notifications_enabled?} # skip users who have notifications disabled
    logger.debug("sending update notification to other editors on this entry with notifications enabled: #{other_editors.collect{|u| u.login}.join(', ')}")
    other_editors.each do |user|
      Email.deliver_update_notification(user, self, change_message, type)
    end
    
    # if this record is part of a DSO's data set, AND the acting user is NOT a "trusted" user
    # send a notification to that DSO
    logger.debug("entry has DSOs? : #{self.data_sharing_orgs.any?}; entry trusts current user? : #{self.trust_user?(User.current_user)}")
    if self.data_sharing_orgs.any? and !self.trust_user?(User.current_user)
      logger.debug("acting user is not trusted for this entry, sending #{type} notification to DSO editors...")
      self.data_sharing_orgs.each do |dso|
        unless self.destruction_in_progress
          # set the entry's status to "unverified"
          DataSharingOrgsTaggable.set_status(dso, self, false)
        end

        # send a notification to that DSO
        Email.deliver_dso_update_notification(dso, self, change_message, type)
      end
    end
  end
  
  def notify_related_record_change(how_changed, record, oldvalues = nil)
    if(how_changed == :updated)
      newvalues = record.get_value_hash
      change_message = Common::formatted_change_message(record, oldvalues)
      if(change_message.nil?)
        logger.debug("No changes to report")
        return true
      end

    elsif([:created, :deleted, :added].include?(how_changed))
      change_message = "Related #{record.class} record was #{how_changed}:\n"
      change_message += Common::record_dump(record)

    else
      raise "Unknown parameter value: how_changed=#{how_changed}"
    end
    
    self.send_notifications(change_message, :update)
    return true
  end
  
  def notify_destroy
    self.destruction_in_progress = true
    logger.debug("sending removal notification for: #{self.name} (##{self.id})")
    if User.current_user
      user = User.current_user.login
    else
      user = '(unknown)'
    end
    self.send_notifications("This entry is being removed from the directory by #{user}", :delete)
    return true
  end
  
  def notify_changes
    change_message = Common::formatted_change_message(self, @oldvalues)
    if(change_message.nil?)
      logger.debug("No changes to report")
      return true
    end
    logger.debug("sending update notification for: #{self.name} (##{self.id})")
    
    self.send_notifications(change_message, :update)
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
    # org_types.collect{|ot| ot.root_term}.uniq
    # [OrgType.find_by_name("Producer Cooperative")]
    tags.select{|t| t.relevant_to? "OrgType"}.map{|x| x.effective_root}
  end
  
  def get_member_orgs
    # member_orgs.collect{|mo| mo.root_term}.uniq
    tags.select{|t| t.relevant_to? "MemberOrg"}.map{|x| x.effective_root}
  end


  def get_sectors
    tags.select{|t| t.relevant_to? "Sector"}.map{|x| x.effective_root}
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
    # temporarily hijacking for tags
    # self.sectors.collect{|sect| sect.name}.join(', ')
    self.tags.map{|t| t.synonyms}.flatten.collect{|t| t.name}.uniq.join(' ; ')
  end
  
  def org_types_to_s
    self.org_types.map{|x| x.tags}.flatten.collect{|t| t.name}.uniq.join(' ; ')
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
  
  # def xlongitude
  #   return Float(self.filtered_longitude) if self.respond_to? "filtered_longitude"
  #   if self.primary_location
  #     self.primary_location.longitude
  #   else
  #     nil
  #   end
  # end
  
  # def xlatitude
  #   return Float(self.filtered_latitude) if self.respond_to? "filtered_latitude"
  #   if self.primary_location
  #     self.primary_location.latitude
  #   else
  #     nil
  #   end
  # end

  def get_primary
    Location.get_primary_for(self)
  end

  def Organization.split_pro_con(lst) 
    choices = lst.map{|x| [x.starts_with?("-"), x.gsub(/^-/,"")]}
    [choices.select{|x| !x[0]}.map{|x| x[1]}, 
     choices.select{|x| x[0]}.map{|x| x[1]}]
  end

  def Organization.location_join(filters,opts = {})
    entity = opts[:entity] || "Organization"
    entities = entity.downcase.pluralize

    select = []
    order = []

    country_filter = ApplicationHelper.get_filter(filters,:country_filter,opts)
    state_filter = ApplicationHelper.get_filter(filters,:state_filter,opts)
    city_filter = ApplicationHelper.get_filter(filters,:city_filter,opts)
    zip_filter = ApplicationHelper.get_filter(filters,:zip_filter,opts)
    within_filter = ApplicationHelper.get_filter(filters,:within_filter,opts)
    loc_filter = ApplicationHelper.get_filter(filters,:loc_filter,opts)

    condSQLs = []
    condParams = []
    join_type = "INNER"
    if [country_filter,state_filter,city_filter,zip_filter].compact.collect{|f| f.length}.inject(0){|a,b| a+b}==0
      join_type = "LEFT"
    end
    # if entity == "Organization"
    joinSQL = "#{join_type} JOIN locations ON locations.taggable_id = #{entities}.id AND locations.taggable_type = '#{entity}'"
    #else
    #  joinSQL = "#{join_type} JOIN locations ON (locations.taggable_id = #{entities}.id AND locations.taggable_type = '#{entity}') OR (locations.taggable_id = organizations.id AND locations.taggable_type = 'Organization')"
    #end

    unless country_filter.nil? or country_filter.empty?
      logger.debug("applying session country filters to search results: #{country_filter.inspect}")
      countries = [country_filter].flatten
      condSQLs << "(locations.physical_country IN (#{countries.collect{'?'}.join(',')})) OR (locations.mailing_country IN (#{countries.collect{'?'}.join(',')}))"
      condParams += countries + countries
    end

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

    origin = nil

    unless zip_filter.nil? or zip_filter.empty?
      logger.debug("applying session zip filters to search results: #{zip_filter.inspect}")
      if within_filter.nil? or within_filter.empty? or within_filter.length != 1 or !(loc_filter.nil? or loc_filter.blank?)
        zips = [zip_filter].flatten.collect{|x| x.to_s + "%"}
        # zips = [zip_filter].flatten.collect{|x| x.sub('*','%')}
        zip_str = zips.collect{|z| "(locations.physical_zip LIKE ?)"}.join(" OR ")
        # condSQLs << "(locations.physical_zip IN (#{cities.collect{'?'}.join(',')})) OR (locations.mailing_zip IN (#{cities.collect{'?'}.join(',')}))"
        condSQLs << zip_str
        condParams += zips
      else
        origin = [zip_filter].flatten[0].to_s
      end
    end

    unless loc_filter.nil? or loc_filter.empty?
      origin = Location.find(loc_filter[0].to_i)
    end

    unless origin.nil? or within_filter.nil? or within_filter.empty? or within_filter.length != 1
      # Within filter takes single zip code
      withins = [within_filter].flatten
      distance, unit = withins[0].split(' ')
      unit = "miles" if unit.nil?
      if unit.downcase[0] == "kms"[0]
        unit = :kms
      else
        unit = :miles
      end
      distance = distance.to_f
      if (distance-distance.to_i).abs<0.001
        distance = distance.to_i
      end

      distance_sql = Location.distance_sql(Geokit::LatLng.normalize(origin),unit)
      bounds = GeoKit::Bounds.from_point_and_radius(origin, distance, :units=>unit) 

      condSQLs << "locations.latitude >= ?"
      condSQLs << "locations.latitude <= ?"
      condSQLs << "locations.longitude >= ?"
      condSQLs << "locations.longitude <= ?"
      # need to repeat formula (distance field not avail to WHERE, could use
      # HAVING but probably slower for important cases)
      condSQLs << "#{distance_sql} <= ?"
      condParams << bounds.sw.lat
      condParams << bounds.ne.lat
      condParams << bounds.sw.lng
      condParams << bounds.ne.lng
      condParams << distance

      select << "#{distance_sql} AS distance"
      select << "'#{unit.to_s}' AS distance_unit"
      order << "distance ASC"

      # For debugging offline, set origin to: "42.59,-72.6"
    end

    return [joinSQL, condSQLs, condParams, select, order]
  end

  def Organization.tag_join(filters, opts = {})
    entity = opts[:entity] || "Organization"
    entities = entity.downcase.pluralize

    dso_filter = ApplicationHelper.get_filter(filters,:dso_filter,opts)
    org_type_filter = ApplicationHelper.get_filter(filters,:org_type_filter,opts) || []
    sector_filter = ApplicationHelper.get_filter(filters,:sector_filter,opts) || []
    legal_structure_filter = ApplicationHelper.get_filter(filters,:legal_structure_filter,opts) || []
    condSQLs = []
    condParams = []
    joinSQL = ""
    unless dso_filter.nil? or dso_filter.empty?
      logger.debug("applying session dso filters to search results: #{dso_filter.inspect}")
      if entity == "Organization"
        joinSQL = "#{joinSQL} INNER JOIN data_sharing_orgs_taggables ON data_sharing_orgs_taggables.taggable_id = #{entities}.id AND data_sharing_orgs_taggables.taggable_type = '#{entity}' INNER JOIN data_sharing_orgs ON data_sharing_orgs_taggables.data_sharing_org_id = data_sharing_orgs.id"
      else
        joinSQL = "#{joinSQL} INNER JOIN data_sharing_orgs_taggables ON (data_sharing_orgs_taggables.taggable_id = #{entities}.id AND data_sharing_orgs_taggables.taggable_type = '#{entity}') OR (data_sharing_orgs_taggables.taggable_id = organizations.id AND data_sharing_orgs_taggables.taggable_type = 'Organization') INNER JOIN data_sharing_orgs ON data_sharing_orgs_taggables.data_sharing_org_id = data_sharing_orgs.id"
      end

      # joinSQL = "#{joinSQL} INNER JOIN data_sharing_orgs_organizations ON data_sharing_orgs_organizations.organization_id = organizations.id INNER JOIN data_sharing_orgs ON data_sharing_orgs_organizations.data_sharing_org_id = data_sharing_orgs.id"
      dsos = [dso_filter].flatten
      # condSQLs << "data_sharing_orgs_taggables.taggable_type = ?"
      # condParams << entity
      condSQLs << "data_sharing_orgs.name IN (#{dsos.collect{'?'}.join(',')})"
      condParams += dsos
    end

    tag_filters = [[org_type_filter, OrgType],
                   [sector_filter, Sector],
                   [legal_structure_filter, LegalStructure]]

    tag_filters.each do |filter,klass|
      unless filter.nil? or filter.empty?
        pro, con = Organization.split_pro_con(filter)

        logger.debug("applying session tag filters to search results: #{filter.inspect}")
        name = klass.to_s

        unless pro.empty?
          tags = pro.map{|x| Tag.find_by_name_and_root_type(x,name)}.compact.map{|x| x.synonyms}.flatten
          tags = [0] if tags.length == 0
          joinSQL = "#{joinSQL} INNER JOIN taggings AS taggings_#{name} ON taggings_#{name}.taggable_id = organizations.id"
          condSQLs << "taggings_#{name}.taggable_type = ?"
          condParams += ["Organization"]
          condSQLs << "taggings_#{name}.tag_id IN (#{tags.collect{'?'}.join(',')})"
          condParams += tags.map{|x| x.id}
        end

        unless con.empty?
          tags = con.map{|x| Tag.find_by_name_and_root_type(x,name)}.compact.map{|x| x.synonyms}.flatten
          tags = [0] if tags.length == 0
          condSQLs << "NOT EXISTS (SELECT 1 FROM taggings WHERE taggings.taggable_id = organizations.id AND taggings.taggable_type = ? AND taggings.tag_id IN (#{tags.collect{'?'}.join(',')}))"
          condParams += ["Organization"]
          condParams += tags.map{|x| x.id}
        end
      end
    end
    
    return [joinSQL, condSQLs, condParams, [], []]
  end

  def Organization.all_join(filters,opts = {})
    joinSQL, condSQLs, condParams, select, order = Organization.location_join(filters,opts)
    joinSQL2, condSQLs2, condParams2, select2, order2 = Organization.tag_join(filters,opts)
    joinSQL = joinSQL + joinSQL2
    condSQLs = condSQLs + condSQLs2
    condParams = condParams + condParams2
    select = select + select2
    order = order + order2
    return [joinSQL,condSQLs,condParams,select,order]
  end

  def Organization.latest_changes(filters)
    joinSQL, condSQLs, condParams, sel = Organization.all_join(filters)
    conditions = []
    conditions = [condSQLs.collect{|c| "(#{c})"}.join(' AND ')] + condParams unless condSQLs.empty?
    logger.debug("After applying filters, conditions = #{conditions.inspect}")
    Organization.find(:all, :select => ApplicationHelper.get_org_select(sel), :order => 'organizations.updated_at DESC', 
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

  def summary_text
    txt = locations.to_s
    if website
      txt = txt + " / " + website
    end
    txt
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end 

  def oname
    "o" + (name.nil? ? "" : name)
  end
end
