class GenericFilesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_parameters, only: [:create, :update]
  before_filter :load_generic_file, only: [:show, :update, :destroy]
  before_filter :load_intellectual_object, only: [:update, :create, :save_batch, :index]

  after_action :verify_authorized, :except => [:create, :index]

  def index
    authorize @intellectual_object
    respond_to do |format|
      # Return active files only, not deleted files!
      format.json { render json: @intellectual_object.active_files.map do |f| f.serializable_hash end }
    end
  end

  def show
    authorize @generic_file
    respond_to do |format|
      format.json { render json: object_as_json }
      format.html {
        @events = Kaminari.paginate_array(@generic_file.premisEvents.events).page(params[:page]).per(10)
        render html: @generic_file
      }
    end
  end

  def create
    authorize @intellectual_object, :create_through_intellectual_object?
    @generic_file = @intellectual_object.generic_files.new(params[:generic_file])
    @generic_file.state = 'A'
    respond_to do |format|
      if @generic_file.save
        format.json { render json: object_as_json, status: :created }
      else
        format.json { render json: @generic_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # /api/v1/objects/:intellectual_object_identifier/files/save_batch
  #
  # save_batch creates or updates a batch of GenericFile objects, along
  # with their related PremisEvents. Although there's no built-in limit
  # on the number of files you can save in a batch, you should limit
  # batches to 200 or so files to avoid a response timeout.
  #
  # This methods determines whether to update an existing GenericFile
  # or create a new one. It then adds any related events to the new/updated
  # GenericFile.
  #
  # Before save_batch, saving a GenericFile required 7 HTTP calls:
  #
  # - 1 x check if file exists
  # - 1 x save or update file
  # - 5 x save generic file event
  #
  # Saving 200 generic files required 1400 HTTP calls. Now it requires 1.
  def save_batch
    generic_files = []
    current_object = nil
    authorize @intellectual_object, :create_through_intellectual_object?
    begin
      params[:generic_files].each do |gf|
        current_object = "GenericFile #{gf[:identifier]}"
        gf_without_events = gf.except(:premisEvents)
        # Load the existing generic file, or create a new one.
        generic_file = (GenericFile.where(tech_metadata__identifier_ssim: gf[:identifier]).first ||
                        @intellectual_object.generic_files.new(gf_without_events))
        generic_file.save!
        generic_files.push(generic_file)
        gf[:premisEvents].each do |event|
          current_object = "Event #{event[':type']} id #{event[:identifier]} for #{gf[:identifier]}"
          generic_file.add_event(event)
        end
      end

      respond_to { |format| format.json { render json: array_as_json(generic_files), status: :created } }
    rescue Exception => ex
      generic_files.each do |gf|
        gf.destroy
      end
      respond_to { |format| format.json {
          render json: { error: "#{ex.message} : #{current_object}" }, status: :unprocessable_entity }
      }
    end
  end


  def update
    authorize @generic_file
    @generic_file.state = 'A'
    if resource.update(params_for_update)
      head :no_content
    else
      render json: resource.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @generic_file, :soft_delete?
    pending = ProcessedItem.pending?(@generic_file.intellectual_object.identifier)
    if pending == 'false'
      attributes = { type: 'delete',
                     date_time: "#{Time.now}",
                     detail: 'Object deleted from S3 storage',
                     outcome: 'Success',
                     outcome_detail: current_user.email,
                     object: 'Ruby aws-s3 gem',
                     agent: 'https://github.com/marcel/aws-s3/tree/master',
                     outcome_information: "Action requested by user from #{current_user.institution_pid}"
      }
      @generic_file.soft_delete(attributes)
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Delete job has been queued for file: #{@generic_file.uri}"
          redirect_to @generic_file.intellectual_object
        }
      end
    else
      redirect_to :back
      flash[:alert] = "Your object cannot be deleted at this time due to a pending #{pending} request."
    end
  end

  protected

  def filter_parameters
    params[:generic_file] &&= params.require(:generic_file).permit(:uri, :content_uri, :identifier, :size, :created,
                                                                   :modified, :file_format,
                                                                   checksum_attributes: [:digest, :algorithm, :datetime])
  end

  # When updating a generic file, the client will likely send back
  # copy of the GenericFile object that includes checksum attributes.
  # If we don't filter those out, Hydra will simply append those
  # checksums to the original checksums, and every time the GenericFile
  # is updated, the number of checksums doubles. We really only want
  # to save the checksums when the GenericFile is created. After that,
  # we'll do fixity checks to make sure they haven't changed, and those
  # checks will be recorded as PremisEvents.
  # Fixes bug https://www.pivotaltracker.com/story/show/73796812
  def params_for_update
    params[:generic_file] &&= params.require(:generic_file).permit(:uri, :content_uri, :identifier, :size, :created,
                                                                   :modified, :file_format)
  end


  def resource
    @generic_file
  end

  def load_intellectual_object
    if params[:intellectual_object_identifier]
      objId = params[:intellectual_object_identifier].gsub(/%2F/i, '/')
      @intellectual_object ||= IntellectualObject.where(desc_metadata__identifier_ssim: objId).first
      params[:intellectual_object_id] = @intellectual_object.id
    elsif params[:intellectual_object_id]
      @intellectual_object ||= IntellectualObject.find(params[:intellectual_object_id])
    else
      @intellectual_object ||= GenericFile.find(params[:id]).intellectual_object
    end
  end

  # Override Fedora's default JSON serialization for our API
  def object_as_json
    if params[:include_relations]
      @generic_file.serializable_hash(include: [:checksum, :premisEvents])
    else
      @generic_file.serializable_hash()
    end
  end

  # Given a list of GenericObjects, returns a list of serializable
  # hashes that include checksum and PremisEvent data. That hash is
  # suitable for JSON serialization back to the API client.
  def array_as_json(list_of_generic_files)
    list_of_generic_files.map { |gf| gf.serializable_hash(include: [:checksum, :premisEvents]) }
  end

  # Load generic file by identifier, if we got that, or by id if we got an id.
  # Identifiers always start with data/, so we can look for a slash. Ids include
  # a urn, a colon, and an integer. They will not include a slash.
  def load_generic_file
    if params[:generic_file_identifier]
      gfid = params[:generic_file_identifier].gsub(/%2F/i, '/')
      @generic_file ||= GenericFile.where(tech_metadata__identifier_ssim: gfid).first
      # Solr permissions handler expects params[:id] to be the object ID,
      # and will blow up if it's not. So humor it.
      params[:id] = @generic_file.id
    elsif params[:id]
      @generic_file ||= GenericFile.find(params[:id])
    end
  end

end
