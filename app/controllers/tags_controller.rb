class TagsController < ApplicationController
  before_filter :admin_required, :only => [:index, :new, :create, :edit, :update, :destroy, :update_identities]

  def index
    @tags = Tag.find(:all).sort{|x,y| x.literal_qualified_name <=> y.literal_qualified_name}

    respond_to do |format|
      format.html
      format.xml  { render :xml => @tags }
    end
  end

  def show
    @tag = Tag.find(params[:id])
    respond_to do |format|
      format.html
      format.xml  { render :xml => @tag }
    end
  end


  def search
    search = params[:search]
    search = "" if search.nil?
    search = search.gsub(/ \(.*/,'')

    lowlevel = params[:exact] || false

    if search.length == 0
      search = "dcc"
    end

    exact, closest = Tag.find_by_qualified_name(search)
    if exact
      hits = []
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
    hits.each do |h|
      if closest
        next if h.parent != closest and h != closest
      end
      results << {
        :name => h.qualified_name,
        :label => lowlevel ? h.literal_qualified_name : h.readable_name,
        :family => "tags",
        :id => h.id
      }
    end
    #results.uniq!{|x| x[:name]} # aww, our ruby is too old
    results = results.group_by{|x| x[:name]}.collect{|n, v| v[0]} unless lowlevel
    results.sort!{|x,y| x[:name].downcase <=> y[:name].downcase}

    render :json => results.to_json
  end

  def update_identities
    @count = Tag.update_all_identities
  end
end
