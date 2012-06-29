class MemberOrgsController < ApplicationController
  before_filter :login_required, :only => [:associate, :dissociate]
  before_filter :admin_required, :only => [:new, :create, :edit, :update, :destroy]
  def dissociate
    @member_org = MemberOrg.find(params[:member_org_id])
    @organization = Organization.find(params[:organization_id])
    merge_check
    @organization.member_orgs.delete(@member_org)
    @organization.save!
    @organization.notify_related_record_change(:deleted, @member_org)
    render :partial => 'manage'
  end

  def associate
    @member_org = MemberOrg.find(params[:member_org_id])
    @organization = Organization.find(params[:organization_id])
    merge_check
    @organization.member_orgs.push(@member_org)
    @organization.save!
    @organization.notify_related_record_change(:added, @member_org)
    render :partial => 'manage'
  end

  # GET /member_orgs
  # GET /member_orgs.xml
  def index
    show_tag_context(MemberOrg)
  end

  # GET /member_orgs/1
  # GET /member_orgs/1.xml
  def show
    show_tag(MemberOrg.find(params[:id]))
  end

  # GET /member_orgs/new
  # GET /member_orgs/new.xml
  def new
    @member_org = MemberOrg.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @member_org }
    end
  end

  # GET /member_orgs/1/edit
  def edit
    @member_org = MemberOrg.find(params[:id])
  end

  # POST /member_orgs
  # POST /member_orgs.xml
  def create
    #AJAX:   Parameters: {"member_org"=>{"name"=>"memorg1"}, "commit"=>"Create", "organization_id"=>"796"}
    #HTTP:   Parameters: {"member_org"=>{"name"=>"newmemberorg1", "custom"=>"1"}, "commit"=>"Create"}
    #HTTP:   Parameters: {"member_org"=>{"name"=>"newmemberorg1", "custom"=>"0"}, "commit"=>"Create"}
    @member_org = MemberOrg.new(params[:member_org])
    unless params[:organization_id].blank?  # as invoked via admin interface
      @organization = Organization.find(params[:organization_id])
      merge_check
      @member_org.organizations.push(@organization)
    end

    respond_to do |format|
      if @member_org.save
        flash[:notice] = 'MemberOrg was successfully created.'
        format.html { redirect_to(@member_org) }
        format.xml  { render :xml => @member_org, :status => :created, :location => @member_org }
        format.js  { render :partial => 'manage' }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @member_org.errors, :status => :unprocessable_entity }
        format.js  { render :partial => 'manage' }
      end
    end
  end

  # PUT /member_orgs/1
  # PUT /member_orgs/1.xml
  def update
    @member_org = MemberOrg.find(params[:id])

    respond_to do |format|
      if @member_org.update_attributes(params[:member_org])
        flash[:notice] = 'MemberOrg was successfully updated.'
        format.html { redirect_to(@member_org) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @member_org.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /member_orgs/1
  # DELETE /member_orgs/1.xml
  def destroy
    @member_org = MemberOrg.find(params[:id])
    @member_org.destroy

    respond_to do |format|
      format.html { redirect_to(member_orgs_url) }
      format.xml  { head :ok }
    end
  end
end
