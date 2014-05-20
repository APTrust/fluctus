class GenericFilesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_parameters

  before_filter :set_intellectual_object, only: [:create, :update]
  #load_and_authorize_resource :intellectual_object, only: [:create, :update]
  #load_and_authorize_resource through: :intellectual_object, only: [:create]

  before_filter :set_generic_file, except: [:create, :update]
  #load_and_authorize_resource except: [:create, :update]

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

  def set_intellectual_object
    search_param = ''
    if params[:intellectual_object_identifier].nil?
      search_param = params[:generic_file_identifier].split("/")
    else
      search_param = params[:intellectual_object_identifier].split("/")
    end
    @intellectual_object = IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: search_param[1], desc_metadata__institution_identifier_tesim: search_param[0]).first
    @institution = @intellectual_object.institution
    params[:id] = @intellectual_object.id
    authorize! params[:action].to_sym, @intellectual_object
  end

  def set_generic_file
    search_params = params[:generic_file_identifier].split("/")
    inst_ident = search_params[0]
    obj_ident = search_params[1]
    filename = ''
    i = 3
    while i < search_params.size
      filename = "#{filename}/#{search_params[i]}"
      i = i+1
    end
    @generic_file = GenericFile.where(desc_metadata__institution_identifier_tesim: inst_ident, desc_metadata__intellectual_object_identifier_tesim: obj_ident, desc_metadata__generic_file_identifier_tesim: filename)
    @intellectual_object = @generic_file.intellectual_object
    @institution = @intellectual_object.institution
    params[:id] = @generic_file.id
    authorize! params[:action].to_sym, @generic_file
  end

  def filter_parameters
    params[:generic_file] &&= params.require(:generic_file).permit(:uri, :content_uri, :size, :created, :modified, :format, checksum_attributes: [:digest, :algorithm, :datetime])
  end

  def resource
    @generic_file
  end
end
