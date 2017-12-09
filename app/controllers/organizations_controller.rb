class OrganizationsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :become_editor, :compare]
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
    @organization = Organization.find(params[:id])
    if !@organization.accessible?(current_user) and 
      (params[:token].nil? or params[:token] != @organization.email_response_token)
      flash[:error] = "You may not view that entry."
      redirect_to :controller => 'search' and return
    end

    @peers = []
    if @organization.grouping
      @peers = Organization.find_all_by_grouping(@organization.grouping).select{ 
        |x| x.id != @organization.id
      }
      past = DateTime.now - 10000.years
      @peers = @peers.sort_by { |x| x.updated_at || past }
      @peers.reverse!
    end
    @orgs = [@organization] + @peers

    @all_verified_dsos = @orgs.map{|x| x.verified_dsos}.flatten.compact.uniq

    #if not(@organization.latitude)
    #  @organization.save_ll
    #  @organization.save
    #end

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

  # GET /organizations/1/elaborate
  def elaborate
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
        format.html { redirect_to :action => 'elaborate', :id => @organization }
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
    merging = !params[:incoming].nil?
    if merging
      @organization1 = @organization
      @organization2 = Organization.find(params[:incoming])
    end
    respond_to do |format|
      if @organization.update_attributes(params[:organization])
        flash[:notice] = 'Organization was successfully updated.'
        format.html { 
          if merging 
            render :action => 'merge'
          else 
            redirect_to(@organization) 
          end 
        }
        format.xml  { head :ok }
      else
        format.html { 
          flash[:notice] = 'Organization was not updated correctly.'
          if merging
            render :action => 'merge'
          else
            render :action => 'edit'
          end
        }
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
      format.html { redirect_to :action => (if params[:recent] then 'recent' else 'index' end), :controller => "search" }
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

  def merge
    @organization = Organization.find(params[:id])
    @organization1 = @organization
    @organization2 = Organization.find(params[:incoming])
    render :action => 'merge', :id => @organization
  end

  def destroy_in_place
    @organization = Organization.find(params[:id])
    @organization.destroy

    if session[:merge_search]
      head :ok
    else
      redirect_to :action => 'index', :controller => "search"
    end
  end

  def untarget
    @organization = Organization.find(params[:id])
    session[:merge] = nil
    flash[:notice] = "Main version no longer set."
    if session[:merge_search]
      redirect_to :controller => 'search', :action => 'search', :params => session[:merge_search]
    else
      render :action => 'show', :id => @organization
    end
  end

  def target
    @organization = Organization.find(params[:id])
    m = session[:merge]
    session[:merge] = { :id => params[:id], :name => @organization.name }
    flash[:notice] = "Set as target for merging."
    if session[:merge_search]
      redirect_to :controller => 'search', :action => 'search', :params => session[:merge_search]
    else
      render :action => 'show', :id => @organization
    end
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
