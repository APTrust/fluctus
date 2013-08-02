class DescriptionObjectsController < ApplicationController
  before_action :set_description_object, only: [:show, :edit, :update, :destroy]

  # GET /description_objects
  # GET /description_objects.json
  def index
    @description_objects = DescriptionObject.all
  end

  # GET /description_objects/1
  # GET /description_objects/1.json
  def show
  end

  # GET /description_objects/new
  def new
    @description_object = DescriptionObject.new
  end

  # GET /description_objects/1/edit
  def edit
  end

  # POST /description_objects
  # POST /description_objects.json
  def create
    @description_object = DescriptionObject.new(description_object_params)

    respond_to do |format|
      if @description_object.save
        format.html { redirect_to @description_object, notice: 'Description object was successfully created.' }
        format.json { render action: 'show', status: :created, location: @description_object }
      else
        format.html { render action: 'new' }
        format.json { render json: @description_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /description_objects/1
  # PATCH/PUT /description_objects/1.json
  def update
    respond_to do |format|
      if @description_object.update_attributes(description_object_params)
        format.html { redirect_to @description_object, notice: 'Description object was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @description_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /description_objects/1
  # DELETE /description_objects/1.json
  def destroy
    @description_object.destroy
    respond_to do |format|
      format.html { redirect_to description_objects_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_description_object
      @description_object = DescriptionObject.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def description_object_params
      params[:description_object]
    end
end
