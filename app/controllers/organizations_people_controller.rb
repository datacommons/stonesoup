class OrganizationsPeopleController < ApplicationController
  # GET /organizations_people
  # GET /organizations_people.xml
  def index
    @organizations_people = OrganizationsPerson.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @organizations_people }
    end
  end

  # GET /organizations_people/1
  # GET /organizations_people/1.xml
  def show
    @organizations_person = OrganizationsPerson.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organizations_person }
    end
  end

  # GET /organizations_people/new
  # GET /organizations_people/new.xml
  def new
    @organizations_person = OrganizationsPerson.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organizations_person }
    end
  end

  # GET /organizations_people/1/edit
  def edit
    @organizations_person = OrganizationsPerson.find(params[:id])
  end

  # POST /organizations_people
  # POST /organizations_people.xml
  def create
    @organizations_person = OrganizationsPerson.new(params[:organizations_person])
    @person = @organizations_person.person
    @organization = @organizations_person.organization

    respond_to do |format|
      if @organizations_person.save
        flash[:notice] = 'Organizational Association was successfully created.'
        format.html { redirect_to(@organizations_person) }
        format.xml  { render :xml => @organizations_person, :status => :created, :location => @organizations_person }
        format.js   { render :partial => 'manage' + '_for_' + params[:context] }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organizations_person.errors, :status => :unprocessable_entity }
        format.js   { render :partial => 'manage' + '_for_' + params[:context] }
      end
    end
  end

  # PUT /organizations_people/1
  # PUT /organizations_people/1.xml
  def update
    @organizations_person = OrganizationsPerson.find(params[:id])
    @person = @organizations_person.person
    @organization = @organizations_person.organization
    merge_check

    respond_to do |format|
      if @organizations_person.update_attributes(params[:organizations_person])
        flash[:notice] = 'Organizational Association was successfully updated.'
        format.html { redirect_to(@organizations_person) }
        format.xml  { head :ok }
        format.js   { render :partial => 'manage' + '_for_' + params[:context] }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organizations_person.errors, :status => :unprocessable_entity }
        format.js   { render :partial => 'manage' + '_for_' + params[:context] }
      end
    end
  end

  def move
    @organizations_person = OrganizationsPerson.find(params[:id])
    @organization = @organizations_person.organization
    merge_check
    @organizations_person.update_attributes({:organization_id => @organization1.id})
    flash[:notice] = 'Person was successfully updated.'
    respond_to do |format|
      format.html { redirect_to(@organizations_people_url) }
      format.xml  { head :ok }
      format.js   { render :partial => 'manage_for_orgs' }
    end
  end

  # DELETE /organizations_people/1
  # DELETE /organizations_people/1.xml
  def destroy
    @organizations_person = OrganizationsPerson.find(params[:id])
    @person = @organizations_person.person
    @organization = @organizations_person.organization
    merge_check

    @organizations_person.destroy

    respond_to do |format|
      format.html { redirect_to(organizations_people_url) }
      format.xml  { head :ok }
      format.js   { render :partial => 'manage' + '_for_' + params[:context] }
    end
  end
end
