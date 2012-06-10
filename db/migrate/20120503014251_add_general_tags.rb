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
      t.string :friendly_name
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

    root_tables = ["OrgType", 
                   "MemberOrg", 
                   "Sector",
                   "LegalStructure"
                   # "ProductService"
                  ]


    friendly_names = {
      "OrgType" => "Type of Organization",
      "MemberOrg" => "Member Organization Affiliation", 
      "Sector" => "Business Sector",
      "LegalStructure" => "Legal Structure"
      # "ProductService" => "Product/Service"
      }

    dcc_world = TagWorld.new(:name => "dcc")
    dcc_world.save!
    dcc = Tag.new(:name => "dcc", :root => dcc_world)
    dcc.save!
    root_tables.each do |name|
      puts "bring across tag types dcc:#{name}"
      context = TagContext.new(:name => name, :friendly_name => friendly_names[name])
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

    link_tables = ["org_types_organizations",
                   "organizations_sectors",
                   "member_orgs_organizations"]

    link_tables.each do |name|
      root = name.gsub(/_?organizations_?/,'')
      puts "bring across tags from #{name} / #{root}"
      begin
        model = name.classify.constantize
      rescue
        model = name.classify.pluralize.constantize
      end
      root_model = root.classify.constantize
      lnk_name = root.singularize + "_id"
      rtype = root.classify
      model.all.each do |t|
        org = Organization.find(t.organization_id)
        lnk = root_model.find(t[lnk_name])
        puts "  #{org} -> #{lnk}"
        tag = Tag.find_by_root_id_and_root_type(root_id = lnk.id,
                                                root_type = rtype)
        Tagging.new(:tag => tag, :taggable => org).save!
      end
    end

    link_fields = ["legal_structure_id"]
    link_fields.each do |name|
      root = name.gsub(/_id/,'')
      puts "bring across tags from #{name} / #{root}"
      model = root.classify.constantize
      rtype = root.classify
      Organization.all.each do |org|
        lnk = org.send root
        next if lnk.nil?
        puts "  #{org} -> #{lnk}"
        tag = Tag.find_by_root_id_and_root_type(root_id = lnk.id,
                                                root_type = rtype)
        Tagging.new(:tag => tag, :taggable => org).save!
      end
    end
    Tag.update_all_identities
  end

  def self.down
    begin
      drop_table :tag_worlds
      drop_table :tag_contexts
      drop_table :taggings
      drop_table :tags
    rescue
    end
  end
end
