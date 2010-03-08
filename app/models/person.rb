class Person < ActiveRecord::Base
  belongs_to :access_rule
  has_many :organizations_people, :dependent => :destroy
  has_many :organizations, :through => :organizations_people
  has_one :user  
end
