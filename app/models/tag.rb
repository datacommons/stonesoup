class Tag < ActiveRecord::Base

  belongs_to :root, :polymorphic => true
  has_many :children, :class_name => "Tag", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Tag"
  belongs_to :effective, :class_name => "Tag"
  has_many :taggings

  def self.update_all_identities
    ct = 0
    Tag.find_all_by_parent_id(nil).each do |t|
      ct = ct + t.update_effective_identities
    end
    return ct
  end

  def synonyms
    return Tag.find_all_by_effective_id(self.id) unless self.effective
    Tag.find_all_by_effective_id(effective.id)
  end

  def taggings_via_synonyms
    self.synonyms.map{|t| t.taggings}.flatten
  end

  def update_effective_identities
    count = 0
    if self.update_effective_identity
      count = 1
      self.save!
    end
    self.children.each do |t|
      count = count + t.update_effective_identities
    end
    # puts "updated #{count} nodes" unless count <= 1
    count
  end

  def effective_parent
    return nil if self.parent.nil?
    return self.parent.effective unless self.parent.effective.nil?
    self.parent
  end

  def effective_root
    return self.effective.root unless self.effective.nil?
    self.root
  end

  def leaf
    r = self.root
    r = self.effective.root unless self.effective.nil?
    r = self if r.nil?
    r
  end

  def update_effective_identity
    eparent = self.effective_parent
    if eparent!=self.parent
      # root doesn't matter, we've been changed at a higher level
      unless self.effective.nil?
        if effective.name == self.name
          if effective.parent == eparent
            # no change needed, we are already set up correctly
            return false
          end
        end
      end
      # we need to find or create a tag with n:self.name and p:eparent
      t = Tag.find_or_create_by_name_and_parent_id(self.name,eparent.id)
      self.effective = t
      return true
    end
    # Our parent, if we have one, is canonical.
    return false if self.root.nil?
    return false if self.root.name == self.name
    unless self.effective.nil?
      return false if self.effective.name = self.root.name
    end

    # We are rooted in an entity that does not match our name.
    # So we are non-canonical.
    t = Tag.find_or_create_by_name_and_root_id_and_root_type(self.root.name,self.root_id,self.root_type)
    self.effective = t
    return true
  end

  def relevant_to?(name)
    ep = self.effective_parent
    return false if ep.nil?
    return false if ep.root_type != "TagContext"
    return ep.root.name == name
  end

  def readable_name
    self.readable_name_rec
  end

  def readable_name_rec
    self.effective.readable_name_rec unless self.effective.nil?
    if self.root
      if self.root.respond_to? "friendly_name"
        return self.root.friendly_name
      end
    end
    n = self.root ? self.root.name : self.name
    ep = self.effective_parent
    return n if ep.nil?
    "#{n} (#{ep.readable_name_rec})"
  end

  def qualified_name
    self.effective.qualified_name unless self.effective.nil?
    #if self.root
    #  if self.root.respond_to? "friendly_name"
    #    return self.root.friendly_name
    #  end
    #end
    n = self.root ? self.root.name : self.name
    ep = self.effective_parent
    return n if ep.nil?
    "#{ep.qualified_name}:#{n}"
  end

  def literal_qualified_name
    return self.name if self.parent.nil?
    "#{self.parent.literal_qualified_name}:#{self.name}"
  end

  def self.find_by_qualified_name(name, cursor = nil)
    parts = name.split(/:/)
    closest = nil
    parts.each do |p|
      cursor = Tag.find_by_name_and_parent_id(p,cursor)
      return [nil, closest] if cursor.nil?
      closest = cursor
    end
    cursor = nil if name[-1,1]==':'
    [cursor, closest]
  end

  def link_name
    name
  end
  
  def link_hash
    {:controller => 'tags', :action => 'show', :id => self.id}
  end

  def accessible?(u)
    true
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end 
end
