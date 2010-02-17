class OrganizationsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :become_editor, :show]
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  # GET /organizations
  # GET /organizations.xml
  def index
    @organizations = Organization.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @organizations }
    end
  end

  # GET /organizations/1
  # GET /organizations/1.xml
  def show
    @entry = @organization = Organization.find(params[:id])
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

    respond_to do |format|
#TODO
#      if current_user.member
#        if params[:make_entry_private]
#          @entry.member = current_user.member
#        else
#          @entry.member = nil
#        end
#      end

      if @organization.save
        @organization.users << current_user if params[:associate_user_to_entry]
        flash[:notice] = 'Organization was successfully created.'
        format.html { redirect_to :controller => 'search', :action => 'search' }
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
#TODO
#      if current_user.member
#        if params[:make_entry_private]
#          @entry.member = current_user.member
#        else
#          @entry.member = nil
#        end
#      end

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

  def become_editor
    @entry = Entry.find(params[:id])
    if request.method == :post
      @entry.users << current_user
      flash[:notice] = "You are now an editor for entry: #{@entry.name}"
      redirect_to :action => 'show', :id => @entry
    end
  end

  def invite
    @entry = Entry.find(params[:id])
    @user = User.find_by_login(params[:user_login])
    unless @user
      @user = User.create(:login => params[:user_login])
      @user.password_cleartext = `pwgen -a 6 1`.chomp
    end
    @user.entries << @entry
    @user.save!
    Email.deliver_invite_for_entry(@user, @entry)
    flash[:notice] = "#{@user.login} has been invited"
    redirect_to :action => 'show', :id => @entry
  end

  protected

  def authorize?(user)
    return true if current_user.is_admin?

    if %w[show edit update destroy become_editor invite].include? action_name
      entry = Organization.find(params[:id])
#TODO
#      if entry.member
#        return entry.member == current_user.member
#      end
    end

    true
  end

  def protect?(action)
#TODO
#    if action_name == 'show'
#      entry = Organization.find(params[:id])
#      return entry.member
#    end

    true
  end

end
