class AccessRule < ActiveRecord::Base
  has_one :organization
  ACCESS_TYPE_PUBLIC = 'PUBLIC'
  ACCESS_TYPE_LOGGEDIN = 'LOGGEDIN'
  ACCESS_TYPE_PRIVATE = 'PRIVATE'
  ACCESS_TYPES = [ACCESS_TYPE_PUBLIC, ACCESS_TYPE_LOGGEDIN, ACCESS_TYPE_PRIVATE]
  ACCESS_TYPE_DESCRIPTION = {
    ACCESS_TYPE_PUBLIC => 'Public - all data is public',
    ACCESS_TYPE_LOGGEDIN => 'Restricted - must be logged in to view',
    ACCESS_TYPE_PRIVATE => 'Private - only editor may view'
  }
  validates_presence_of :access_type
  def AccessRule.cleanse(entries, user)
    entries.reject{|e| !e.accessible?(user)}
  end

  def to_s
    self.access_type
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end
end
