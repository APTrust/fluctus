class IntellectualObjectsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_object, only: [:show, :edit, :update, :destroy, :restore]
  before_filter :load_institution, only: [:index, :create]
  after_action :verify_authorized, :except => [:index, :create, :create_from_json]

  include Aptrust::GatedSearch
  include RecordsControllerBehavior

  apply_catalog_search_params
  self.solr_search_params_logic += [:for_selected_institution]

  def index
    authorize @institution
    @intellectual_objects = @institution.intellectual_objects
    super
  end

  def create
    authorize @institution, :create_through_institution?
    @intellectual_object = @institution.intellectual_objects.new(params[:intellectual_object])
    aggregate = IoAggregation.new
    aggregate.initialize_object(@intellectual_object.id)
    aggregate.save!
    super
  end

  def show
    authorize @intellectual_object
    if @intellectual_object.nil? || @intellectual_object.state == 'D'
      respond_to do |format|
        format.json { render :nothing => true, :status => 404 }
        format.html
      end
    else
      respond_to do |format|
        format.json { render json: object_as_json }
        format.html
      end
    end
  end

  def edit
    authorize @intellectual_object
    super
  end

  def update
    authorize @intellectual_object
    if params[:counter]
      # They are just updating the search counter
      search_session[:counter] = params[:counter]
      redirect_to :action => "show", :status => 303
    else
      # They are updating a record. Use the method defined in RecordsControllerBehavior
      super
    end
  end

  def destroy
    authorize @intellectual_object, :soft_delete?
    pending = ProcessedItem.pending?(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      redirect_to @intellectual_object
      flash[:alert] = 'This item has already been deleted.'
    elsif pending == 'false'
      attributes = { type: 'delete',
                     date_time: "#{Time.now}",
                     detail: 'Object deleted from S3 storage',
                     outcome: 'Success',
                     outcome_detail: current_user.email,
                     object: 'Ruby aws-s3 gem',
                     agent: 'https://github.com/marcel/aws-s3/tree/master',
                     outcome_information: "Action requested by user from #{current_user.institution_pid}"
      }
      resource.soft_delete(attributes)
      respond_to do |format|
        format.json { head :no_content }
        format.html {
          flash[:notice] = "Delete job has been queued for object: #{resource.title}"
          redirect_to root_path
        }
      end
    else
      redirect_to @intellectual_object
      flash[:alert] = "Your object cannot be deleted at this time due to a pending #{pending} request."
    end
  end

  # get 'objects/:id/restore'
  def restore
    authorize @intellectual_object
    pending = ProcessedItem.pending?(@intellectual_object.identifier)
    if @intellectual_object.state == 'D'
      redirect_to @intellectual_object
      flash[:alert] = 'This item has been deleted and cannot be queued for restoration.'
    elsif pending == 'false'
      ProcessedItem.create_restore_request(@intellectual_object.identifier, current_user.email)
      redirect_to @intellectual_object
      flash[:notice] = 'Your item has been queued for restoration.'
    else
      redirect_to @intellectual_object
      flash[:alert] = "Your object cannot be queued for restoration at this time due to a pending #{pending} request."
    end
  end

  def create_from_json
    # new_object is the IntellectualObject we're creating.
    # current_object is the item we're about to save at any
    # given step of this operation. We use this in the rescue
    # clause to let the caller know where the operation failed.
    state = {
      current_object: nil,
      object_events: [],
      object_files: [],
      }
    if params[:include_nested] == 'true'
      begin
        json_param = get_create_params
        object = JSON.parse(json_param.to_json).first
        # We might be re-ingesting a previously-deleted intellectual object,
        # or more likely, creating a new intel obj. Load or create the object.
        identifier = object['identifier'].gsub(/%2F/i, "/")
        new_object = IntellectualObject.where(desc_metadata__identifier_ssim: identifier).first ||
          IntellectualObject.new()
        new_object.state = 'A' # in case we just loaded a deleted object
        # Set the object's attributes from the JSON data.,
        # then authorize and save it.
        object.each { |attr_name, attr_value|
          set_obj_attr(new_object, state, attr_name, attr_value)
        }
        state[:current_object] = "IntellectualObject #{new_object.identifier}"
        load_institution_for_create_from_json(new_object)
        authorize @institution, :create_through_institution?
        new_object.save!
        aggregate = IoAggregation.new
        aggregate.initialize_object(new_object.id)
        aggregate.save!
        # Save the ingest and other object-level events.
        state[:object_events].each { |event|
          state[:current_object] = "IntellectualObject Event #{event['type']} / #{event['identifier']}"
          new_object.add_event(event)
        }
        # Save all the files and their events.
        state[:object_files].each do |file|
          create_generic_file(file, new_object, state)
        end
        @intellectual_object = new_object
        @institution = @intellectual_object.institution
        respond_to { |format| format.json { render json: object_as_json, status: :created } }
      rescue Exception => ex
        if !new_object.nil?
          new_object.generic_files.each do |gf|
            gf.destroy
          end
          new_object.destroy
        end
        respond_to { |format| format.json {
            render json: { error: "#{ex.message} : #{state[:current_object]}" },
            status: :unprocessable_entity
          }
        }
      end
    end
  end

  protected

  # Override Hydra-editor to redirect to an alternate location after create
  def redirect_after_update
    intellectual_object_path(resource)
  end

  private

  def get_create_params
    params[:intellectual_object].is_a?(Array) ? json_param = params[:intellectual_object] : json_param = params[:intellectual_object][:_json]
  end

  def create_generic_file(file, intel_obj, state)
    # Create a new generic file object, or load the existing one.
    # We may have an existing generic file if this intellectual
    # object was previously deleted and is now being re-ingested.
    gfid = file['identifier'].gsub(/%2F/i, '/')
    new_file = GenericFile.where(tech_metadata__identifier_ssim: gfid).first || GenericFile.new()
    file_events, file_checksums = []
    file.each { |file_attr_name, file_attr_value|
      case file_attr_name
      when 'premisEvents'
        file_events = file_attr_value
      when 'checksum'
        file_checksums = file_attr_value
      else
        new_file[file_attr_name.to_s] = file_attr_value.to_s
      end }
    file_checksums.each { |checksum| new_file.techMetadata.checksum.build(checksum) }
    state[:current_object] = "GenericFile #{new_file.identifier}"
    new_file.intellectual_object = intel_obj
    new_file.state = 'A' # in case we loaded a deleted file
    new_file.save!
    aggregate = IoAggregation.where(identifier: intel_obj.id).first
    aggregate.update_aggregations('add', new_file)
    file_events.each { |event|
      state[:current_object] = "GenericFile Event #{event['type']} / #{event['identifier']}"
      new_file.add_event(event)
    }
  end

  def set_obj_attr(new_object, state, attr_name, attr_value)
    case attr_name
    when 'institution_id'
      attr_value.to_s.include?(':') ? new_object.institution = Institution.find(attr_value.to_s) : new_object.institution = Institution.where(desc_metadata__identifier_ssim: attr_value.to_s).first
    when 'premisEvents'
      state[:object_events] = attr_value
    when 'generic_files'
      state[:object_files] = attr_value
    else
      new_object[attr_name.to_s] = attr_value.to_s
    end
  end

  def for_selected_institution(solr_parameters, user_parameters)
    return unless params[:institution_id]
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{params[:institution_id]}")
  end

  # Override Blacklight so that it has the "institution_id" set even when we're on a show page (e.g. /objects/foo:123)
  def search_action_url options = {}
    institution_intellectual_objects_path(params[:institution_id] || @intellectual_object.institution_id)
  end

  # Override Fedora's default JSON serialization for our API
  # Note that we return only active files, not deleted files
  def object_as_json
    if params[:include_relations]
      # Return only active files, but call them generic_files
      data = @intellectual_object.serializable_hash(include: [:premisEvents, active_files: { include: [:checksum, :premisEvents]}])
      data['generic_files'] = data.delete('active_files')
      data['state'] = @intellectual_object.state
      data
    else
      @intellectual_object.serializable_hash()
    end
  end

  def intellectual_object_params
    params.require(:intellectual_object).permit(:pid, :institution_id, :title,
                                                :description, :access, :identifier,
                                                :bag_name, :alt_identifier)
  end

  def load_object
    if params[:identifier] && params[:id].blank?
      identifier = params[:identifier].gsub(/%2F/i, "/")
      @intellectual_object ||= IntellectualObject.where(desc_metadata__identifier_ssim: identifier).first

      # Solr permissions handler expects params[:id] to be the object ID,
      # and will blow up if it's not. So humor it.
      if @intellectual_object.nil?
        msg = "IntellectualObject '#{params[:identifier]}' not found"
        raise ActionController::RoutingError.new(msg)
      else
        params[:id] = @intellectual_object.id if @intellectual_object
      end
    else
      #@intellectual_object ||= IntellectualObject.find(params[:id])
      @intellectual_object ||= IntellectualObject.get_from_solr(params[:id])
      #@files = IntellectualObject.files_from_solr(params[:id], {rows: 1000, start: 0})
    end
  end

  def load_institution
    #@institution ||= Institution.find(params[:institution_id])
    @institution ||= Institution.get_from_solr(params[:institution_id])
  end

  def load_institution_for_create_from_json(object)
    @institution = params[:institution_id].nil? ? object.institution : Institution.find(params[:institution_id])
  end

end
