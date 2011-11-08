class LocationsController < ApplicationController
  before_filter :login_required
  before_filter :admin_required, :only => [:index, :show]
protected  
	def process_params(params)
	  if params[:location_mailing_same_as_physical]
	    Location::ADDRESS_FIELDS.each do |fld|
  	    params[:location]['mailing_' + fld] = params[:location]['physical_' + fld]
      end
    end
    params.delete(:location_mailing_same_as_physical)
	end
public

  # GET /locations
  # GET /locations.xml
  def index
    @locations = Location.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @locations }
    end
  end

  # GET /locations/1
  # GET /locations/1.xml
  def show
    @location = Location.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @location }
    end
  end

  # GET /locations/new
  # GET /locations/new.xml
  def new
    @location = Location.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @location }
    end
  end

  # GET /locations/1/edit
  def edit
    @location = Location.find(params[:id])
  end

  # POST /locations
  # POST /locations.xml
  def create
    process_params(params)
    @organization = Organization.find(params[:id])
    merge_check
    @location = @organization.locations.create(params[:location])
    @location.save!
    flash[:notice] = 'Location was successfully created.'
    respond_to do |format|
      format.html { redirect_to(@location) }
      format.xml  { render :xml => @location, :status => :created, :location => @location }
      format.js   { render :partial => 'manage', :locals => {:location => @location, :expanded => true, :new_expanded => true} }
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
		logger.debug("error caught in locations#create. @location=#{@location}")
    respond_to do |format|
      format.html { render :action => "new" }
      format.xml  { render :xml => @location.errors, :status => :unprocessable_entity }
      format.js   { render :partial => 'manage', :locals => {:location => @location, :expanded => true, :new_expanded => true} }
    end
  end

  # PUT /locations/1
  # PUT /locations/1.xml
  def update
    @location = Location.find(params[:id])
    @organization = @location.organization
    merge_check

    respond_to do |format|
      if @location.update_attributes(params[:location])
        flash[:notice] = 'Location was successfully updated.'
        format.html { redirect_to(@location) }
        format.xml  { head :ok }
        format.js   { render :partial => 'manage', :locals => {:location => @location} }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @location.errors, :status => :unprocessable_entity }
        format.js   { render :partial => 'manage', :locals => {:location => @location, :existing_expanded => @location.id} }
      end
    end
  end

  def move
    @location = Location.find(params[:id])
    @organization = @location.organization
    merge_check
    @location.update_attribute(:organization_id, @organization1.id)
    if @organization2.primary_location == @location
      @organization2.update_attribute(:primary_location, nil)
    end
    flash[:notice] = 'Location was successfully updated.'
    respond_to do |format|
      format.html { redirect_to(@location) }
      format.xml  { head :ok }
      format.js   { render :partial => 'manage', :locals => {:location => @location} }
    end
  end

  # DELETE /locations/1
  # DELETE /locations/1.xml
  def destroy
    @location = Location.find(params[:id])
    @organization = @location.organization
    merge_check
    @location.destroy
    
    respond_to do |format|
      format.html { redirect_to(locations_url) }
      format.xml  { head :ok }
      format.js { render :partial => 'manage' }
    end
  end
end
