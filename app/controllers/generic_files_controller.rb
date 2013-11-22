class GenericFilesController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_generic_file, only: [:show, :edit, :update]

  actions :show, :edit, :update

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_generic_file
    @generic_file = GenericFile.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def generic_file_params
    params[:generic_file]
  end
end
