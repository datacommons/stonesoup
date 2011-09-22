require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  has_and_belongs_to_many :organizations # as editor
  belongs_to :person
  has_and_belongs_to_many :data_sharing_orgs
  cattr_accessor :current_user

  attr_accessor :password_cleartext
  before_update :crypt_unless_empty
  
  attr_protected :is_admin

  before_validation_on_create :crypt_password

  VALID_EMAIL_REGEX = /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
  
  def member_of_dso?(dso)
    self.data_sharing_orgs.include?(dso)
  end
  
  def self.authenticate(login, pass)
    find(:first, :conditions =>["login = ? AND password = ?", login, sha1(pass)])
  end  

  def change_password(pass)
    update_attribute "password", self.class.sha1(pass)
  end

  def is_admin?
    is_admin
  end

  # rather than serializing entire user object to session, just dump id & load
  def _dump(ignored)
    self.id.to_s
  end

  def self._load(id)
    find(id)
  end
    
protected

  def self.sha1(pass)
    Digest::SHA1.hexdigest("ROTFL--#{pass}--")
  end
    
  before_create :crypt_password
  
  def crypt_password
    write_attribute("password", self.class.sha1(password))
  end

  validates_length_of :login, :within => 3..40
  validates_presence_of :login, :password
  validates_format_of :login, :with => VALID_EMAIL_REGEX, :message => 'should be a valid e-mail address'
  validates_uniqueness_of :login, :on => :create
  validates_confirmation_of :password_cleartext, :on => :create     
  validates_length_of :password_cleartext, :within => Common::PASSWORD_MIN_LENGTH..40, :message => 'must be at least %d characters', :if => Proc.new { |user| user.new_record? or (!user.new_record? and !user.password_cleartext.nil?) }
  validates_each :password_cleartext do |record, attr, value|
    # validate password only for new user creation or existing user password update
    if record.new_record? or (!record.new_record? and !value.nil?)
      record.errors.add attr, Common::INVALID_PASSWORD_MESSAGE unless Common::valid_password?(value, record.login)
    end
  end

  # Before saving the record to database we will crypt the password 
  # using SHA1. 
  # We never store the actual password in the DB.
  def crypt_password
    if password_cleartext && !password_cleartext.empty?
      write_attribute "password", self.class.sha1(password_cleartext)
    else
      write_attribute "password", nil
    end
  end

  # If the record is updated we will check if the password is empty.
  # If its empty we assume that the user didn't want to change his
  # password and just reset it to the old value.
  def crypt_unless_empty
    if password_cleartext.blank?
      user = self.class.find(self.id)
      self.password = user.password
    else
      write_attribute "password", self.class.sha1(password_cleartext)
    end        
  end  

public
  def link_name
    if self.person.nil?
      reg = /^[A-Z0-9._%+-]+@/i
      prefix = self.login.scan(reg)
      if prefix.length
        prefix[0] + "..."
      else
        "(hidden)"
      end
    elsif self.person.respond_to?('link_name')
      self.person.link_name
    end
  end

  def link_hash
    if self.person.nil?
      nil
    elsif self.person.respond_to?('link_hash')
      self.person.link_hash
    end
  end
  
  def to_s
    self.login
  end
  
  def can_edit?(entry)
    return true if self.is_admin? # admin's can edit anything
    case entry.class.to_s
    when Person.to_s
      if entry.user.nil?  # if there's no login user associated with the Person record, anyone may edit it
        return true
      elsif entry.user == self # if there is, only that user may edit it
        return true
      else
        return false
      end
    when Organization.to_s
      if entry.users.include?(self) # only the entry's editors may edit the record
        return true
      else
        return false
      end
    else
      raise "Unknown entry type: #{entry.class}"
    end
  end

  def self.hashify(pass)
    sha1(pass)
  end
  
  def User.get_all
    User.find(:all, :order => 'login')
  end
end
