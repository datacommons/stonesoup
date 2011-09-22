class DataSharingOrgsController < ApplicationController
  before_filter :login_required, :only => [:show, :link_org, :unlink_org]
  before_filter :admin_required, :only => [:index, :new, :create, :edit, :update, :destroy, :link_user, :unlink_user]
  
  def link_org
    dso = DataSharingOrg.find(params[:data_sharing_org_id])
    org = Organization.find(params[:organization_id])
    unless current_user.member_of_dso?(dso)
      flash[:error] = "You must be a member of the DSO to modify the data pool."
    else
      if(DataSharingOrgsOrganization.set_status(dso, org, params[:verified] || false))
        status = (params[:verified] ? 'verified' : 'unverified')
        flash[:notice] = "#{org.name} was successfully added to the data pool for #{dso.name} as #{status}"
      else
        flash[:error] = "Couldn't add Org to DSO"
      end
    end
    redirect_to org
  end
  
  def unlink_org
    dso = DataSharingOrg.find(params[:data_sharing_org_id])
    org = Organization.find(params[:organization_id])
    unless current_user.member_of_dso?(dso)
      flash[:error] = "You must be a member of the DSO to modify the data pool."
    else
      link = DataSharingOrgsOrganization.get_status(dso, org)
      link.destroy unless link.nil?
      flash[:notice] = "#{org.name} was successfully removed from the data pool for #{dso.name}"
    end
    redirect_to org
  end
  
  def link_user
    dso = DataSharingOrg.find(params[:data_sharing_org_id])
    user = User.find(params[:user_id])
    dso.users.push(user)
    if dso.save
      flash[:notice] = "Linked user #{user.login} as a member of #{dso.name}"
    else
      flash[:error] = "Couldn't link user #{user.login} as a member of #{dso.name}: #{dso.errors.full_messages.inspect}"
    end
    redirect_to dso
  end

  def unlink_user
    dso = DataSharingOrg.find(params[:data_sharing_org_id])
    user = User.find(params[:user_id])
    dso.users.delete(user)
    if dso.save
      flash[:notice] = "Un-linked user #{user.login} as a member of #{dso.name}"
    else
      flash[:error] = "Couldn't un-link user #{user.login} as a member of #{dso.name}: #{dso.errors.full_messages.inspect}"
    end
    redirect_to dso
  end

  # GET /data_sharing_orgs
  # GET /data_sharing_orgs.xml
  def index
    @data_sharing_orgs = DataSharingOrg.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @data_sharing_orgs }
    end
  end

  # GET /data_sharing_orgs/1
  # GET /data_sharing_orgs/1.xml
  def show
    @data_sharing_org = DataSharingOrg.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @data_sharing_org }
    end
  end

  # GET /data_sharing_orgs/new
  # GET /data_sharing_orgs/new.xml
  def new
    @data_sharing_org = DataSharingOrg.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @data_sharing_org }
    end
  end

  # GET /data_sharing_orgs/1/edit
  def edit
    @data_sharing_org = DataSharingOrg.find(params[:id])
  end

  # POST /data_sharing_orgs
  # POST /data_sharing_orgs.xml
  def create
    @data_sharing_org = DataSharingOrg.new(params[:data_sharing_org])

    respond_to do |format|
      if @data_sharing_org.save
        flash[:notice] = 'DataSharingOrg was successfully created.'
        format.html { redirect_to(@data_sharing_org) }
        format.xml  { render :xml => @data_sharing_org, :status => :created, :location => @data_sharing_org }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @data_sharing_org.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /data_sharing_orgs/1
  # PUT /data_sharing_orgs/1.xml
  def update
    @data_sharing_org = DataSharingOrg.find(params[:id])

    respond_to do |format|
      if @data_sharing_org.update_attributes(params[:data_sharing_org])
        flash[:notice] = 'DataSharingOrg was successfully updated.'
        format.html { redirect_to(@data_sharing_org) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @data_sharing_org.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /data_sharing_orgs/1
  # DELETE /data_sharing_orgs/1.xml
  def destroy
    @data_sharing_org = DataSharingOrg.find(params[:id])
    @data_sharing_org.destroy

    respond_to do |format|
      format.html { redirect_to(data_sharing_orgs_url) }
      format.xml  { head :ok }
    end
  end
end
