class GenericFilesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_parameters
  load_and_authorize_resource :intellectual_object, only: [:create, :update]
  load_and_authorize_resource through: :intellectual_object, only: [:create]
  load_and_authorize_resource except: [:create, :update]

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

  def update
    @generic_file = @intellectual_object.generic_files.where(uri: params[:id]).first
    authorize! :update, resource 
    if resource.update(params[:generic_file])
      head :no_content
    else
      render json: resource.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @generic_file.soft_delete
    respond_to do |format|
      format.json { head :no_content }
      format.html {
        flash[:notice] = "Delete job has been queued for file: #{@generic_file.uri}"
        redirect_to @generic_file.intellectual_object
      }
    end
  end

  protected

  def filter_parameters
    params[:generic_file] &&= params.require(:generic_file).permit(:uri, :content_uri, :size, :created, :modified, :format, checksum_attributes: [:digest, :algorithm, :datetime])
  end

  def resource
    @generic_file
  end
end
