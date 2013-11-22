class IntellectualObjectsController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_intellectual_object, only: [:show, :edit, :update]

  actions :show, :edit, :update

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_intellectual_object
    @intellectual_object = IntellectualObject.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def intellectual_object_params
    params[:intellectual_object]
  end
end
