class OrganizationsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :become_editor]
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => [:post, :put, :delete], :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

  # GET /organizations
  # GET /organizations.xml
  def index
    @organizations = Organization.find(:all, :order => 'name')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @organizations }
    end
  end

  # GET /organizations/1
  # GET /organizations/1.xml
  def show
    @organization = @organization = Organization.find(params[:id])
    unless @organization.accessible?(current_user)
      flash[:error] = "You may not view that entry."
      redirect_to :action => 'index' and return
    end

    if not(@organization.latitude)
      @organization.save_ll
      @organization.save
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organization }
      format.csv do
        data = [@organization].flatten
        data = data.map {|r| r.reportable_data}.flatten
        cols = Organization.column_names
        table = Ruport::Data::Table.new(:data => data,
                                        :column_names => cols)
        send_data table.to_csv,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => ("attachment; filename=" + params[:id] + ".csv")
      end
    end
  end

  # GET /organizations/new
  # GET /organizations/new.xml
  def new
    @organization = Organization.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # GET /organizations/1/edit
  def edit
    @organization = Organization.find(params[:id])
  end

  # POST /organizations
  # POST /organizations.xml
  def create
    @organization = Organization.new(params[:organization])
    @organization.set_access_rule(AccessRule::ACCESS_TYPE_PUBLIC)  # TODO: data is public by default?

    respond_to do |format|
      if @organization.save
        @organization.users << current_user if params[:associate_user_to_entry]
        flash[:notice] = 'Organization was successfully created.'
        format.html { redirect_to :action => 'edit', :id => @organization }
        format.xml  { render :xml => @organization, :status => :created, :location => @organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /organizations/1
  # PUT /organizations/1.xml
  def update
    @organization = Organization.find(params[:id])
    @organization.users << current_user if params[:associate_user_to_entry] and !@organization.users.include?(current_user)
    @organization.users.delete(current_user) if params[:disassociate_user_from_entry]
    respond_to do |format|
      if @organization.update_attributes(params[:organization])
        flash[:notice] = 'Organization was successfully updated.'
        format.html { redirect_to(@organization) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /organizations/1
  # DELETE /organizations/1.xml
  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy

    respond_to do |format|
      format.html { redirect_to(organizations_url) }
      format.xml  { head :ok }
    end
  end
  
  def remove_editor
    @organization = Organization.find(params[:id])
    user = User.find(params[:user_id])
    if request.method == :post and !current_user.nil?
      @organization.users.delete(user)
      flash[:notice] = "The user #{user.login} has been removed as an editor for the organization: #{@organization.name}"
      redirect_to :action => 'show', :id => @organization
    end
  end
  
  def become_editor
    @organization = Organization.find(params[:id])
    if request.method == :post and !current_user.nil?
      @organization.users << current_user
      flash[:notice] = "You are now an editor for organization: #{@organization.name}"
      redirect_to :action => 'show', :id => @organization
    end
  end

  def invite
    @organization = Organization.find(params[:id])
    @user = User.find_by_login(params[:user_login])
    unless @user
      @user = User.create(:login => params[:user_login])
      @user.password_cleartext = random_password(params[:user_login])
      flash[:error] = "Login user account created for #{params[:user_login]}"
    end
    if @user.organizations.include?(@organization)
      flash[:notice] = "#{@user.login} is already an editor for this entry"
    else
      @user.organizations << @organization
      @user.save!
      Email.deliver_invite_for_org(@user, @organization)
      flash[:notice] = "#{@user.login} has been invited"
    end
    redirect_to :action => 'show', :id => @organization
  end

  protected

  def authorize?(user)
    return true if current_user.is_admin?

    if %w[show edit update destroy become_editor invite].include? action_name
      organization = Organization.find(params[:id])
    end

    true
  end
end
