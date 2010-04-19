class PeopleController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :me]
  def me
    if current_user.person.nil?
      redirect_to :action => 'new'
    else
      redirect_to :action => 'edit', :id => current_user.person
    end
  end
  
  # GET /people
  # GET /people.xml
  def index
    @people = Person.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @people }
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show
    @person = Person.find(params[:id])
    unless @person.accessible?(current_user)
      flash[:error] = "You may not view that entry."
      redirect_to :action => 'index' and return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    @person = Person.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
    if !@person.user.nil? and @person.user != current_user
      flash[:error] = "You may not edit this entry, it is owned by another user."
      redirect_to :action => 'show', :id => @person and return
    end
  end

  # POST /people
  # POST /people.xml
  def create
    @person = Person.new(params[:person])
    @person.set_access_rule(params[:access_rule])
    @person.user = current_user if params[:is_me]

    respond_to do |format|
      if @person.save
        @person.access_rule.save
        flash[:notice] = 'Person was successfully created.'
        format.html { redirect_to(@person) }
        format.xml  { render :xml => @person, :status => :created, :location => @person }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.xml
  def update
    @person = Person.find(params[:id])
    @person.user = current_user if params[:is_me] and @person.user.nil?
    @person.set_access_rule(params[:access_rule][:access_type]) unless params[:access_rule].nil?

    respond_to do |format|
      if @person.update_attributes(params[:person])
        @person.access_rule.save
        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml
  def destroy
    @person = Person.find(params[:id])
    @person.destroy

    respond_to do |format|
      format.html { redirect_to(people_url) }
      format.xml  { head :ok }
    end
  end
end
