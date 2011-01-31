class Person < ActiveRecord::Base
  belongs_to :access_rule
  has_many :organizations_people, :dependent => :destroy
  has_many :organizations, :through => :org_associations
  has_one :user

  acts_as_ferret(:fields => {
    :name => {:boost => 2.0, :store => :yes },
    :access_type => { :store => :yes }
  })

  def access_type
    self.access_rule.access_type
  end
  
  def Person.latest_changes(filters)
    user = User.current_user  # from Organization.latest_changes
    conditions = if user && user.is_admin?
      nil
    end
    Person.find(:all, :order => 'updated_at DESC', 
               :limit => 15,
               :conditions => conditions)
  end

  def name
    firstname + ' ' + lastname
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
end
