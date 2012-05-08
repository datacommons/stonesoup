class LegalStructuresController < ApplicationController
  before_filter :admin_required, :only => [:index, :new, :create, :edit, :update, :destroy]
  # GET /legal_structures
  # GET /legal_structures.xml
  def index
    @legal_structures = LegalStructure.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @legal_structures }
    end
  end

  # GET /legal_structures/new
  # GET /legal_structures/new.xml
  def new
    @legal_structure = LegalStructure.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @legal_structure }
    end
  end

  # GET /legal_structures/1/edit
  def edit
    @legal_structure = LegalStructure.find(params[:id])
  end

  def show
    @legal_structure = LegalStructure.find(params[:id])
  end

  # POST /legal_structures
  # POST /legal_structures.xml
  def create
    @legal_structure = LegalStructure.new(params[:legal_structure])

    respond_to do |format|
      if @legal_structure.save
        flash[:notice] = 'LegalStructure was successfully created.'
        format.html { redirect_to(legal_structures_url) }
        format.xml  { render :xml => @legal_structure, :status => :created, :location => @legal_structure }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @legal_structure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /legal_structures/1
  # PUT /legal_structures/1.xml
  def update
    @legal_structure = LegalStructure.find(params[:id])

    respond_to do |format|
      if @legal_structure.update_attributes(params[:legal_structure])
        flash[:notice] = 'LegalStructure was successfully updated.'
        format.html { redirect_to(legal_structures_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @legal_structure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /legal_structures/1
  # DELETE /legal_structures/1.xml
  def destroy
    @legal_structure = LegalStructure.find(params[:id])
    @legal_structure.destroy

    respond_to do |format|
      format.html { redirect_to(legal_structures_url) }
      format.xml  { head :ok }
    end
  end
end
