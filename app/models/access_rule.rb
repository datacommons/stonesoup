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
end
