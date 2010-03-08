require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  has_and_belongs_to_many :organizations # as editor
  cattr_accessor :current_user

  attr_accessor :password_cleartext
  before_update :crypt_unless_empty

  before_validation_on_create :crypt_password

  has_and_belongs_to_many :entries
  belongs_to :member
  #attr_protected :member_id  #will want this for security soon...

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
  #validates_length_of :password, :within => 5..40
  validates_presence_of :login, :password
  validates_uniqueness_of :login, :on => :create
  validates_confirmation_of :password_cleartext, :on => :create     

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

end
