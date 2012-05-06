class Tag < ActiveRecord::Base
  belongs_to :root, :polymorphic => true
  has_many :children, :class_name => "Tag", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Tag"
  belongs_to :effective, :class_name => "Tag"
  has_many :taggings

  def self.update_all_identities
    Tag.find_all_by_parent_id(nil).each do |t|
      t.update_effective_identities
    end
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
    puts "updated #{count} nodes" unless count <= 1
    count
  end

  def effective_parent
    return nil if self.parent.nil?
    return self.parent.effective unless self.parent.effective.nil?
    self.parent
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
end
