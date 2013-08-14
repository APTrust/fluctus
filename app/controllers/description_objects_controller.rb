class DescriptionObjectsController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_description_object, only: [:show, :edit, :update]

  actions :show, :edit, :update

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
