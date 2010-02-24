class LocationsController < ApplicationController
  layout 'application'

protected  
	def create_location_from_form(org, params)
		# at least a city must be specified
		return if params['new_location'].nil? or params['new_location']['physical_city'].blank?
		return org.create_address(params[:new_location])
	end
	
	def process_params(params)
	  if params[:new_location_mailing_same_as_physical]
	    Location::ADDRESS_FIELDS.each do |fld|
  	    params[:new_location]['mailing_' + fld] = params[:new_location]['physical_' + fld]
      end
    end
    params.delete(:new_location_mailing_same_as_physical)
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
  		@location = create_location_from_form(@organization, params)
  		#TODO: catch validation errors

    respond_to do |format|
      if @location.save
        flash[:notice] = 'Location was successfully created.'
        format.html { redirect_to(@location) }
        format.xml  { render :xml => @location, :status => :created, :location => @location }
        format.js   { render :partial => 'manage' }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @location.errors, :status => :unprocessable_entity }
        format.js   { render_text "couldn't create location: " + @location.errors }
      end
    end
  end

  # PUT /locations/1
  # PUT /locations/1.xml
  def update
    @location = Location.find(params[:id])

    respond_to do |format|
      if @location.update_attributes(params[:location])
        flash[:notice] = 'Location was successfully updated.'
        format.html { redirect_to(@location) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @location.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /locations/1
  # DELETE /locations/1.xml
  def destroy
    @location = Location.find(params[:id])
    @organization = @location.organization
    @location.destroy
    
    respond_to do |format|
      format.html { redirect_to(locations_url) }
      format.xml  { head :ok }
      format.js { render :partial => 'manage' }
    end
  end
end
