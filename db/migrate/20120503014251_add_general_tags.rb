class AddGeneralTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name
      t.integer :root_id
      t.string :root_type
      t.integer :parent_id
      t.integer :effective_id
      t.timestamps
    end

    create_table :taggings do |t|
      t.integer :tag_id
      t.integer :taggable_id
      t.string :taggable_type
      t.datetime :created_at
    end

    create_table :tag_contexts do |t|
      t.string :name
    end

    create_table :tag_worlds do |t|
      t.string :name
    end

    add_index :tags, :name
    add_index :tags, [:root_id, :root_type]
    add_index :tags, :parent_id
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type]
    add_index :tag_contexts, :name
    add_index :tag_worlds, :name

    root_tables = ["OrgType", "MemberOrg", "Sector"]

    dcc_world = TagWorld.new(:name => "dcc")
    dcc_world.save!
    dcc = Tag.new(:name => "dcc", :root => dcc_world)
    dcc.save!
    root_tables.each do |name|
      context = TagContext.new(:name => name)
      context.save!
      parent = Tag.new(:name => name, :root => context)
      parent.parent = dcc
      parent.save!
      
      model = name.classify.constantize
      roots = model.all
      roots = reject{|x| x.custom?} if model.respond_to? "custom?"
      
      roots.each do |root|
        name = root.name
        if root.respond_to? "synonym_of"
          root = root.synonym_of unless root.synonym_of.nil?
        end
        tag = Tag.new(:name => name)
        tag.parent = parent
        tag.root = root
        tag.save!
      end
    end

  end

  def self.down
    drop_table :tag_worlds
    drop_table :tag_contexts
    drop_table :taggings
    drop_table :tags
  end
end
