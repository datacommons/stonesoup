class EntriesController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :become_editor]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @entry_pages, @entries = paginate :entries, :per_page => 10
  end

  def show
    @entry = Entry.find(params[:id])
  end

  def new
    @entry = Entry.new
  end

  def create
    @entry = Entry.new(params[:entry])
    if @entry.save
      @entry.users << current_user if params[:associate_user_to_entry]
      flash[:notice] = 'Entry was successfully created.'
      redirect_to :controller => 'search', :action => 'search'
    else
      render :action => 'new'
    end
  end

  def edit
    @entry = Entry.find(params[:id])
  end

  def update
    @entry = Entry.find(params[:id])
    if @entry.update_attributes(params[:entry])
      flash[:notice] = 'Entry was successfully updated.'
      redirect_to :action => 'show', :id => @entry
    else
      render :action => 'edit'
    end
  end

  def destroy
    Entry.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def become_editor
    @entry = Entry.find(params[:id])
    if request.method == :post
      @entry.users << current_user
      flash[:notice] = "You are now an editor for entry: #{@entry.name}"
      redirect_to :action => 'show', :id => @entry
    end
  end
end
