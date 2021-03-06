class OrgTypesController < ApplicationController
  before_filter :login_required, :only => [:associate, :dissociate]
  before_filter :admin_required, :only => [:index, :new, :create, :edit, :update, :destroy]
  # :show is ok
  def dissociate
    @org_type = OrgType.find(params[:org_type_id])
    @organization = Organization.find(params[:organization_id])
    merge_check
    @organization.org_types.delete(@org_type)
    @organization.save!
    @organization.notify_related_record_change(:deleted, @org_type)
    render :partial => 'manage'
  end

  def associate
    @org_type = OrgType.find(params[:org_type_id])
    @organization = Organization.find(params[:organization_id])
    merge_check
    @organization.org_types.push(@org_type)
    @organization.save!
    @organization.notify_related_record_change(:added, @org_type)
    render :partial => 'manage'
  end
  
  # GET /org_types
  # GET /org_types.xml
  def index
    show_tag_context(OrgType)
  end

  # GET /org_types/1
  # GET /org_types/1.xml
  def show
    show_tag(OrgType.find(params[:id]))
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
    # search for an existing record
    @org_type = OrgType.find_by_name(params[:org_type][:name])
    if(@org_type.nil?)
      # if not found, create it
      @org_type = OrgType.new(params[:org_type])
    end
    unless params[:organization_id].blank?  # as invoked via admin interface
      @organization = Organization.find(params[:organization_id])
      merge_check
      @org_type.organizations.push(@organization)
    end

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
