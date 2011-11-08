class ProductServicesController < ApplicationController
protected  
	def create_product_service_from_form(org, params)
		return nil if params[:new_product_service].nil? or params[:new_product_service][:name].blank?
		ps = org.products_services.create(params[:new_product_service])
		ps.save!
		return ps
	end
public

  # GET /product_services
  # GET /product_services.xml
  def index
    @product_services = ProductService.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @product_services }
    end
  end

  # GET /product_services/1
  # GET /product_services/1.xml
  def show
    @product_service = ProductService.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @product_service }
    end
  end

  # GET /product_services/new
  # GET /product_services/new.xml
  def new
    @product_service = ProductService.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @product_service }
    end
  end

  # GET /product_services/1/edit
  def edit
    @product_service = ProductService.find(params[:id])
  end

  # POST /product_services
  # POST /product_services.xml
  def create
    @organization = Organization.find(params[:id])
    @product_service = create_product_service_from_form(@organization, params)
    merge_check

    respond_to do |format|
      if @product_service.save
        flash[:notice] = 'ProductService was successfully created.'
        format.html { redirect_to(@product_service) }
        format.xml  { render :xml => @product_service, :status => :created, :location => @product_service }
        format.js   { render :partial => 'manage' }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @product_service.errors, :status => :unprocessable_entity }
        format.js   { render :partial => 'manage' }
      end
    end
  end

  # PUT /product_services/1
  # PUT /product_services/1.xml
  def update
    @product_service = ProductService.find(params[:id])
    @organization = @product_service.organization
    merge_check

    respond_to do |format|
      if @product_service.update_attributes(params[:product_service])
        flash[:notice] = 'ProductService was successfully updated.'
        format.html { redirect_to(@product_service) }
        format.xml  { head :ok }
        format.js { render :partial => 'manage' }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @product_service.errors, :status => :unprocessable_entity }
        format.js { render :partial => 'manage' }
      end
    end
  end

  def move
    @product_service = ProductService.find(params[:id])
    @organization = @product_service.organization
    merge_check

    @product_service.update_attribute(:organization_id, @organization1.id)
    flash[:notice] = 'ProductService was successfully updated.'
    respond_to do |format|
      format.html { redirect_to(@product_service) }
      format.xml  { head :ok }
      format.js   { render :partial => 'manage' }
    end
  end


  # DELETE /product_services/1
  # DELETE /product_services/1.xml
  def destroy
    @product_service = ProductService.find(params[:id])
    @organization = @product_service.organization
    merge_check

    @product_service.destroy

    respond_to do |format|
      format.html { redirect_to(product_services_url) }
      format.xml  { head :ok }
      format.js { render :partial => 'manage' }
    end
  end

end
