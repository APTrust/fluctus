class DescriptionObjectsController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_description_object, only: [:show, :edit, :update]

  # GET /description_objects/1
  # GET /description_objects/1.json
  def show
  end

  # GET /description_objects/1/edit
  def edit
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
