class DataSharingOrgsController < ApplicationController
  before_filter :admin_or_DSOmembership_required, :only => [:show, :edit, :update, :link_org, :unlink_org, :import]
  before_filter :admin_required, :only => [:index, :new, :create, :destroy, :link_user, :unlink_user]
protected
  def admin_or_DSOmembership_required
    unless session[:user] # must be logged in
      access_denied and return false
    else
      # admin's can access everything
      return true if session[:user] and session[:user].is_admin?
      # user is not admin, checking data access
      if(!params[:data_sharing_org_id].blank?)
        dso_id = params[:data_sharing_org_id]
      elsif(!params[:id].blank?)
        dso_id = params[:id]
      else
        logger.error("no DSO ID found, denying access by default")
        access_denied and return false
      end
      dso = DataSharingOrg.find(dso_id)
      if(dso.nil?)
        logger.error("no DSO found with id #{dso_id}")
        access_denied and return false
      end
      if current_user.member_of_dso?(dso)
        return true
      else
        access_denied("You must be a member of the DSO to access that page.") and return false
      end
    end
  end
public
  def import
    dso_id = params[:data_sharing_org_id]
    @dso = DataSharingOrg.find(dso_id)
    
    errors = []
    if(params[:file].blank?)
      errors.push "You must upload a data file to be imported."
    else
      raw_csv_data = params[:file].read
    end

    @plugin_name = params[:plugin_name]
    if @plugin_name.blank?
      errors.push "You must select the import plugin name."
    else
      # update default, if needed
      if(@dso.default_import_plugin_name != @plugin_name)
        @dso.default_import_plugin_name = @plugin_name 
        if @dso.save
          logger.debug("Updated DSO's default_import_plugin_name to: #{@plugin_name}")
        else
          flash[:error] = "Couldn't save default_import_plugin_name to DSO record: #{@dso.errors.full_messages.inspect}"
        end
      end
    end

    @import_status = params[:import_status]
    if @import_status.blank?
      errors.push "You must select the default import status."
    end
    
    unless errors.empty?
      flash[:error] = "The import could not be processed for the following reasons:\n<ul><li>"+ errors.join('</li><li>') + '</li></ul>'
      @data_sharing_org = @dso
      #TODO: load "Data Import" tab instead of default
      render :action => 'show' and return
    end

    self.require "#{IMPORT_PLUGINS_DIRECTORY}/#{@plugin_name}"
    require 'faster_csv'

    # statistics variables
    error_messages = []
    infos = []
    lines_read = 0
    created = 0
    updated = 0
    errors = 0
    
    case @import_status
    when 'optin'
      default_access_type = AccessRule::ACCESS_TYPE_PRIVATE
    when 'optout', 'optout-silent'
      default_access_type = AccessRule::ACCESS_TYPE_PUBLIC
    else
      raise "Unknown import status: '#{@import_status}'"
    end
    
    # read our data file
    FasterCSV.parse(raw_csv_data, :headers => true, :return_headers => false ) do |entry|
      lines_read = lines_read + 1
      
      result = Module.const_get(@plugin_name.camelcase).parse_line(entry, @dso, default_access_type)
      
      if(result[:record_status] != :error)  # import successful, record was created or updated
        organization = result[:record]
        logger.debug("Processed record imported for #{organization.name}")
        
        case result[:record_status]
        when :created
          created += 1
          # send email followup based on import preferences
          case @import_status
          when 'optin'
            logger.debug("Sending opt-in confirmation email...")
            Email.deliver_optin_confirmation(organization) unless organization.email.blank?
          when 'optout'
            logger.debug("Sending opt-out notification email...")
            Email.deliver_optout_notification(organization) unless organization.email.blank?
          #when 'optout-silent' # no notification
          end
        when :updated
          updated += 1
        else
          raise "Unknown record_status returned by import plug-in: '#{result[:record_status]}'"
        end
        # set verification status for this org/DSO
        DataSharingOrgsOrganization.set_status(@dso, organization, true)

      else
        errors += result[:errors].length
      end
      # handle general result[:errors] messages
      error_messages += result[:errors] if !result[:errors].nil? and result[:errors].any?
    end
  rescue Exception => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    error_messages.push e.message
    errors += 1
  ensure
    @stats = {:records_read_from_csv => lines_read,
      :records_created => created,
      :records_updated => updated,
      :errors => errors}
    @errors = error_messages.uniq
  end
  
  def link_org
    dso = DataSharingOrg.find(params[:data_sharing_org_id])
    org = Organization.find(params[:organization_id])
    unless current_user.member_of_dso?(dso)
      flash[:error] = "You must be a member of the DSO to modify the data pool."
    else
      if(DataSharingOrgsOrganization.set_status(dso, org, params[:verified] || false))
        status = (params[:verified] ? 'verified' : 'unverified')
        flash[:notice] = "#{org.name} was successfully added to the data pool for #{dso.name} as #{status}"
         org.ferret_update
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
