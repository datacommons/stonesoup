class Member < ActiveRecord::Base
  has_many :users
  has_many :entries
end
