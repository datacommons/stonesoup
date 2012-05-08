class TagWorld < ActiveRecord::Base
  has_many :tags, :as => :root
end
