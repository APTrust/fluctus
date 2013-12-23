class GenericFilesController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!

  actions :edit, :update

  def show
    @events = Kaminari.paginate_array(@generic_file.premisEvents.events).page(params[:page]).per(10)
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def build_resource_params
    [params[:generic_file]]
  end
end
