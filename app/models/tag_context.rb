class TagContext < ActiveRecord::Base
  has_many :tags, :as => :root

  def link_name
    friendly_name
  end
  
  def link_hash
    {:controller => name.underscore.pluralize, :action => 'index'}
  end
end
