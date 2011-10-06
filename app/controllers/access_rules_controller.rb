class AccessRulesController < ApplicationController
  before_filter :login_or_token_required, :only => [:set_org_visibility]
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]

  # handles responses from confirmation/notice emails sent on data import
  def set_org_visibility
    status = params[:status]
    org = Organization.find(params[:id])
    unless(AccessRule::ACCESS_TYPES.include?(status))
      flash[:error] = "Sorry, the URL seems to have been mangled. Edit the entry to change the visibility. You'll need to log in first."
      redirect_to edit_organization_path(org) and return
    end
    # org and status are valid, record the response...
    org.response = status
    org.responded_at = Time.now
    org.set_access_rule(status)
    unless(org.save)
      msg = "Saving record failed: #{org.errors.full_messages.inspect}"
      logger.error(msg)
      flash[:error] = msg
    else
      msg = "The visibility of this entry was set to: #{status}. Thank you for stewarding the directory."
      flash[:notice] = msg
      logger.debug(msg)
      if(current_user.nil? or !current_user.organizations.include?(org))
        flash[:notice] += "<br/>Would you like to <a href='" + url_for(:controller => 'organizations', :action => 'become_editor', :id => org.id) + "'>become an editor of this entry</a>? You will need to log in or create a log in account first."
      end
    end
    redirect_to organization_url(org, :token => params[:token])
  end

  # GET /access_rules
  # GET /access_rules.xml
  def index
    @access_rules = AccessRule.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @access_rules }
    end
  end

  # GET /access_rules/1
  # GET /access_rules/1.xml
  def show
    @access_rule = AccessRule.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @access_rule }
    end
  end

  # GET /access_rules/new
  # GET /access_rules/new.xml
  def new
    @access_rule = AccessRule.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @access_rule }
    end
  end

  # GET /access_rules/1/edit
  def edit
    @access_rule = AccessRule.find(params[:id])
  end

  # POST /access_rules
  # POST /access_rules.xml
  def create
    @access_rule = AccessRule.new(params[:access_rule])

    respond_to do |format|
      if @access_rule.save
        flash[:notice] = 'AccessRule was successfully created.'
        format.html { redirect_to(@access_rule) }
        format.xml  { render :xml => @access_rule, :status => :created, :location => @access_rule }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @access_rule.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /access_rules/1
  # PUT /access_rules/1.xml
  def update
    @access_rule = AccessRule.find(params[:id])
    @organization = @access_rule.organization
    
    respond_to do |format|
      if @access_rule.update_attributes(params[:access_rule])
        logger.debug("AccessRule updated successfully")
        flash[:notice] = 'AccessRule was successfully updated.'
        format.html { redirect_to(@access_rule) }
        format.xml  { head :ok }
        format.js   { render :partial => 'manage' }
      else
        logger.debug("AccessRule not updated: #{@access_rule.errors.full_messages.inspect}")
        format.html { render :action => "edit" }
        format.xml  { render :xml => @access_rule.errors, :status => :unprocessable_entity }
        format.js   { render :partial => 'manage' }
      end
    end
  end

  # DELETE /access_rules/1
  # DELETE /access_rules/1.xml
  def destroy
    @access_rule = AccessRule.find(params[:id])
    @access_rule.destroy

    respond_to do |format|
      format.html { redirect_to(access_rules_url) }
      format.xml  { head :ok }
    end
  end
end
