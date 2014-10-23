class GenericFilesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_parameters, only: [:create, :update]
  before_filter :load_generic_file, only: [:show, :update, :destroy]
  before_filter :load_intellectual_object, only: [:update, :create, :save_batch, :index]

  after_action :verify_authorized, :except => [:create, :index]

  include Aptrust::GatedSearch
  self.solr_search_params_logic += [:for_selected_object]
  self.solr_search_params_logic += [:only_generic_files]
  self.solr_search_params_logic += [:add_access_controls_to_solr_params]
  self.solr_search_params_logic += [:only_active_objects]

  def index
    authorize @intellectual_object
    @generic_files = @intellectual_object.generic_files
    respond_to do |format|
      # Return active files only, not deleted files!
      format.json { render json: @intellectual_object.active_files.map do |f| f.serializable_hash end }
      format.html { super }
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
    aggregate = IoAggregation.where(identifier: @intellectual_object.id).first
    aggregate.update_aggregations('add', @generic_file)
    respond_to do |format|
      if @generic_file.save
        format.json { render json: object_as_json, status: :created }
      else
        log_model_error(@generic_file)
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
  #
  # NOTE: The API client submits checksums in a param called :checksum.
  # The remove_existing_checksums method below renames that param to
  # :checksum_attributes. See the doc below on remove_existing_checksums.
  #
  # We have to rewrite the params here so that checksum becomes
  # checksum_attributes. When serializing generic files back to the
  # API client, this app always uses generic_file.checksum. Other
  # contollers, such as the intellectual_object controller, also
  # use generic_file.checksum for both input and output. However, Rails
  # nested resources expects generic_file.checksum_attributes. That
  # means the API has to serialize generic files differently, depending
  # on which endpoint it's talking to, and Rails will reject the same
  # JSON it just sent to the API client.
  #
  # Instead of making the API client guess which JSON format Rails wants,
  # let's make consistent and use generic_file.checksum. We'll change it
  # to checksum_attributes here to satisfy nested resources.
  def save_batch
    generic_files = []
    current_object = nil
    authorize @intellectual_object, :create_through_intellectual_object?
    begin
      params[:generic_files].each do |gf|
        current_object = "GenericFile #{gf[:identifier]}"
        if gf[:checksum].blank?
          raise "GenericFile #{gf[:identifier]} is missing checksums."
        end
        if gf[:premisEvents].blank?
          raise "GenericFile #{gf[:identifier]} is missing Premis Events."
        end
        gf_without_events = gf.except(:premisEvents, :checksum)
        # Change param name to make inherited resources happy.
        gf_without_events[:checksum_attributes] = gf[:checksum]
        # Load the existing generic file, or create a new one.
        generic_file = (GenericFile.where(tech_metadata__identifier_ssim: gf[:identifier]).first ||
                        @intellectual_object.generic_files.new(gf_without_events))
        generic_file.state = 'A'
        if generic_file.id.present?
          # This is an update
          gf_clean_data = remove_existing_checksums(generic_file, gf_without_events)
          generic_file.update(gf_clean_data)
        else
          # New GenericFile
          generic_file.save!
        end
        generic_files.push(generic_file)
        gf[:premisEvents].each do |event|
          current_object = "Event #{event[':type']} id #{event[:identifier]} for #{gf[:identifier]}"
          generic_file.add_event(event)
        end
      end

      respond_to { |format| format.json { render json: array_as_json(generic_files), status: :created } }
    rescue Exception => ex
      log_exception(ex)
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
      aggregate = IoAggregation.where(identifier: @generic_file.intellectual_object.id).first
      update_map = [@generic_file, params_for_update]
      aggregate.update_aggregations('update', update_map)
      head :no_content
    else
      log_model_error(resource)
      render json: resource.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @generic_file, :soft_delete?
    # Don't allow a delete request if an ingest or restore is in process
    # for this object. OK to delete if another delete request is in process.
    result = ProcessedItem.can_delete_file?(@generic_file.intellectual_object.identifier, @generic_file.identifier)
    if @generic_file.state == 'D'
      redirect_to @generic_file
      flash[:alert] = 'This file has already been deleted.'
    elsif result == 'true'
      attributes = { type: 'delete',
                     date_time: "#{Time.now}",
                     detail: 'Object deleted from S3 storage',
                     outcome: 'Success',
                     outcome_detail: current_user.email,
                     object: 'Ruby aws-s3 gem',
                     agent: 'https://github.com/marcel/aws-s3/tree/master',
                     outcome_information: "Action requested by user from #{current_user.institution_pid}"
      }
      aggregate = IoAggregation.where(identifier: @generic_file.intellectual_object.id).first
      aggregate.update_aggregations('delete', @generic_file)
      @generic_file.soft_delete(attributes)
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Delete job has been queued for file: #{@generic_file.uri}"
          redirect_to @generic_file.intellectual_object
        }
      end
    else
      redirect_to @generic_file
      flash[:alert] = "Your file cannot be deleted at this time due to a pending #{result} request."
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
      #@intellectual_object ||= IntellectualObject.find(params[:intellectual_object_id])
      @intellectual_object ||= IntellectualObject.get_from_solr(params[:intellectual_object_id])
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

  # Remove existing checksums from submitted generic file data.
  # We don't want two copies of the same md5 and two of the same sha256.
  # Returns a copy of gf_params with existing checksums removed.
  # This prevents duplicate checksums from accumulating in the metadata.
  def remove_existing_checksums(generic_file, gf_params)
    copy_of_params = gf_params.deep_dup
    generic_file.checksum.each do |existing_checksum|
      copy_of_params[:checksum_attributes].delete_if do |submitted_checksum|
        generic_file.has_checksum?(submitted_checksum[:digest])
      end
    end
    copy_of_params
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
      #@generic_file ||= GenericFile.find(params[:id])
      @generic_file ||=GenericFile.file_from_solr(params[:id])
    end
  end

  def for_selected_object(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{params[:intellectual_object_id]}")
  end

end
