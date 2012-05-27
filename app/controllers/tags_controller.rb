class TagsController < ApplicationController
  before_filter :login_required, :only => [:associate, :dissociate]
  before_filter :admin_required, :only => [:associate_root, :dissociate_root, :new, :create, :edit, :update, :destroy, :update_identities, :dashboard]

  def dissociate_root
    tag = Tag.find(params[:tag_id])
    tag.root = nil
    tag.save!
    @tag = params[:root_type].constantize.find(params[:root_id])
    render :partial => 'search/root_summary'
  end

  def associate_root
    root = params[:root_type].constantize.find(params[:root_id])
    tag = Tag.find(params[:tag_id])
    tag.root = root
    tag.save!
    if params[:view] == "root"
      root.reload
      @tag = root
    else
      @tag = tag
    end
    render :partial => 'search/root_summary'
  end

  def dissociate
    @tagging = Tagging.find(params[:tagging_id])
    @taggable = @tagging.taggable
    @taggable.taggings.delete(@tagging)
    @taggable.save!
    # @taggable.notify_related_record_change(:deleted, @tag)
    @taggable.ferret_update
    @organization = @taggable
    render :partial => 'manage'
  end

  def associate
    if params[:text]
      parent = nil
      if params[:type]
        if params[:type].length > 0
          parent = Tag.find_by_name(params[:type])
        end
      end
      @tag = Tag.create(:name => params[:text], 
                        :parent => parent)
      @tag.save!
    else
      @tag = Tag.find(params[:id])
    end
    @organization = Organization.find(params[:taggable_id])
    merge_check
    @organization.tags.push(@tag)
    @organization.save!
    # @organization.notify_related_record_change(:added, @tag)
    @organization.ferret_update
    render :partial => 'manage'
  end

  def index
    show_tag_context(Tag)
    # @tags = Tag.find(:all).sort{|x,y| x.literal_qualified_name <=> y.literal_qualified_name}
  end

  def show
    show_tag(Tag.find(params[:id]))
  end

  def search
    search = params[:search]
    search = "" if search.nil?
    search = search.gsub(/ \(.*/,'')

    lowlevel = params[:exact] || false

    if search.length == 0
      search = "dcc"
    end

    cursor = nil
    parent = nil
    seed = ""
    if params[:parent]
      seed = params[:parent]
      parent = Tag.find_by_name_and_root_type(seed,"TagContext")
    end
    exact, closest = Tag.find_by_qualified_name(search)
    hits = []
    if exact
      if params[:parent]
        hits = hits + [exact]
      end
      hits = hits + Tag.find_all_by_parent_id(exact.id)
    else
      name = search.gsub(/.*:/,'')
      if name != search
        if closest and name.length == 0
          hits = Tag.find_all_by_parent_id(closest.id)
        elsif closest
          hits = Tag.find(:all, :conditions => ['name LIKE ?', 
                                                (name.length>2 ? "%" : "")+
                                                name+"%"],
                          :limit => 100)
        else
          hits = []
        end
      else
        hits = Tag.find(:all, :conditions => ['name LIKE ?', 
                                              (name.length>2 ? "%" : "")+
                                              name+"%"],
                        :limit => 100)
      end
    end
    results = Array.new
    if params[:parent]
      hits.reject!{|x| x.root_type == "TagContext" or x.root_type == "TagWorld"}
    end
    hits.each do |h|
      if closest
        next if h.parent != closest and h != closest
      end
      results << {
        :name => h.qualified_name,
        :label => lowlevel ? h.literal_qualified_name : h.readable_name,
        :family => "tags",
        :id => h.id,
        :direct => (h.parent == parent || seed == "")
      }
    end
    #results.uniq!{|x| x[:name]} # aww, our ruby is too old
    results = results.group_by{|x| x[:name]}.collect{|n, v| v[0]} unless lowlevel
    results.sort!{|x,y| ((x[:direct] ? 0 : 1) <=> (y[:direct] ? 0 : 1)).nonzero? || (x[:name].downcase <=> y[:name].downcase)}

    render :json => results.to_json
  end

  def update_identities
    @count = Tag.update_all_identities
  end

  def dashboard
    @count = Tag.update_all_identities
    @orphan_tags = Tag.find_all_by_root_type(nil)
    models = [LegalStructure, MemberOrg, OrgType, Sector]
    @orphan_things = []
    models.each do |model|
      name = model.to_s.tableize
      @orphan_things << model.find_by_sql(["SELECT * FROM #{name} WHERE NOT EXISTS (SELECT id FROM tags WHERE #{name}.id = tags.root_id AND tags.root_type = ?)", model.to_s])
    end
    @orphan_things.flatten!
  end
end
