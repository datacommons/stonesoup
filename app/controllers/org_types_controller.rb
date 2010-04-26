class OrgTypesController < ApplicationController
  def dissociate
    @org_type = OrgType.find(params[:org_type_id])
    @organization = Organization.find(params[:organization_id])
    @organization.org_types.delete(@org_type)
    @organization.save!
    render :partial => 'manage'
  end

  def associate
    @org_type = OrgType.find(params[:org_type_id])
    @organization = Organization.find(params[:organization_id])
    @organization.org_types.push(@org_type)
    @organization.save!
    render :partial => 'manage'
  end
  
  # GET /org_types
  # GET /org_types.xml
  def index
    @org_types = OrgType.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @org_types }
    end
  end

  # GET /org_types/1
  # GET /org_types/1.xml
  def show
    @org_type = OrgType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @org_type }
    end
  end

  # GET /org_types/new
  # GET /org_types/new.xml
  def new
    @org_type = OrgType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @org_type }
    end
  end

  # GET /org_types/1/edit
  def edit
    @org_type = OrgType.find(params[:id])
  end

  # POST /org_types
  # POST /org_types.xml
  def create
    @org_type = OrgType.new(params[:new_org_type].merge(:custom => true))
    @organization = Organization.find(params[:organization_id])
    @org_type.organizations.push(@organization)

    respond_to do |format|
      if @org_type.save
        flash[:notice] = 'OrgType was successfully created.'
        format.html { redirect_to(@org_type) }
        format.xml  { render :xml => @org_type, :status => :created, :location => @org_type }
        format.js  { render :partial => 'manage' }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @org_type.errors, :status => :unprocessable_entity }
        format.js  { render :partial => 'manage' }
      end
    end
  end

  # PUT /org_types/1
  # PUT /org_types/1.xml
  def update
    @org_type = OrgType.find(params[:id])

    respond_to do |format|
      if @org_type.update_attributes(params[:org_type])
        flash[:notice] = 'OrgType was successfully updated.'
        format.html { redirect_to(@org_type) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @org_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /org_types/1
  # DELETE /org_types/1.xml
  def destroy
    @org_type = OrgType.find(params[:id])
    @org_type.destroy

    respond_to do |format|
      format.html { redirect_to(org_types_url) }
      format.xml  { head :ok }
    end
  end
end
