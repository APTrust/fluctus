class GenericFilesController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!

  actions :show, :edit, :update

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def generic_file_params
    params[:generic_file]
  end
end
