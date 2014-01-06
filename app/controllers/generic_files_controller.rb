class GenericFilesController < ApplicationController
  before_filter :authenticate_user!
  before_filter do
    params[:generic_file] &&= params.require(:generic_file).permit(:uri, :content_uri, :size, :created, :modified, :format, checksum_attributes: [:digest, :algorithm, :datetime])
  end
  load_and_authorize_resource :intellectual_object, only: :create
  load_and_authorize_resource through: :intellectual_object, only: :create
  load_and_authorize_resource except: :create

  def show
    @events = Kaminari.paginate_array(@generic_file.premisEvents.events).page(params[:page]).per(10)
  end

  def create
    respond_to do |format|
      if resource.save
        format.json { render json: @generic_file, status: :created }
      else
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  protected

  def resource
    @generic_file
  end
end
