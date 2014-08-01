class IntellectualObjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_object, only: [:show, :update]
  load_and_authorize_resource :institution, only: [:index, :create, :create_from_json]
  load_and_authorize_resource :through => :institution, only: [:create]
  load_and_authorize_resource except: [:index, :create, :create_from_json]

  include Aptrust::GatedSearch
  apply_catalog_search_params
  include RecordsControllerBehavior

  self.solr_search_params_logic += [:for_selected_institution]

  def show
    respond_to do |format|
      format.json { render json: object_as_json }
      format.html { render "show" }
    end
  end

  def update
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
    resource.soft_delete
    respond_to do |format|
      format.json { head :no_content }
      format.html {
        flash[:notice] = "Delete job has been queued for object: #{resource.title}"
        redirect_to root_path
      }
    end
  end

  def create_from_json
    if params[:include_nested] == 'true'
      # new_object is the IntellectualObject we're creating.
      # current_object is the item we're about to save at any
      # given step of this operation. We use this in the rescue
      # clause to let the caller know where the operation failed.
      new_object = nil
      current_object = nil
      begin
        params[:intellectual_object].is_a?(Array) ? json_param = params[:intellectual_object] : json_param = params[:intellectual_object][:_json]
        object = JSON.parse(json_param.to_json).first
        new_object = IntellectualObject.new()
        object_events, object_files = []
        object.each { |attr_name, attr_value|
          case attr_name
          when 'institution_id'
            attr_value.to_s.include?(':') ? new_object.institution = Institution.find(attr_value.to_s) : new_object.institution = Institution.where(desc_metadata__identifier_ssim: attr_value.to_s).first
          when 'premisEvents'
            object_events = attr_value
          when 'generic_files'
            object_files = attr_value
          else
            new_object[attr_name.to_s] = attr_value.to_s
          end }
        current_object = "IntellectualObject #{new_object.identifier}"
        new_object.save!
        object_events.each { |event|
          current_object = "IntellectualObject Event #{event['type']} / #{event['identifier']}"
          new_object.add_event(event)
        }
        object_files.each do |file|
          new_file = GenericFile.new()
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
          current_object = "GenericFile #{new_object.identifier}"
          new_file.intellectual_object = new_object
          new_file.save!
          file_events.each { |event|
            current_object = "GenericFile Event #{event['type']} / #{event['identifier']}"
            new_file.add_event(event)
          }
        end
        @intellectual_object = new_object
        @institution = @intellectual_object.institution
        authorize! :create, @intellectual_object
        respond_to { |format| format.json { render json: object_as_json, status: :created } }
      rescue Exception => ex
        if !new_object.nil?
          new_object.generic_files.each do |gf|
            gf.destroy
          end
          new_object.destroy
        end
        puts ex.message
        respond_to { |format| format.json {
            render json: { error: "#{ex.message} : #{current_object}" },
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

  def self.cancan_resource_class
    CanCan::ControllerResource
  end

  private

  def for_selected_institution(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{params[:institution_id]}")
  end

  # Override Blacklight so that it has the "institution_id" set even when we're on a show page (e.g. /objects/foo:123)
  def search_action_url options = {}
    institution_intellectual_objects_path(params[:institution_id] || @intellectual_object.institution_id)
  end

  # Override Fedora's default JSON serialization for our API
  def object_as_json
    if params[:include_relations]
      @intellectual_object.serializable_hash(include: [ :premisEvents, generic_files: { include: [:checksum, :premisEvents]}])
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
      @intellectual_object ||= IntellectualObject.find(params[:id])
    end
  end
end
