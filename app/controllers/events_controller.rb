class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_intellectual_object, if: :intellectual_object_identifier_exists?
  before_filter :load_generic_file, if: :generic_file_identifier_exists?
  before_filter :load_and_authorize_parent_object, only: [:create]
  after_action :verify_authorized, :only => [:index]

  #helper_method :search_action_url

  include Aptrust::GatedSearch

  self.solr_search_params_logic += [:only_events]
  self.solr_search_params_logic += [:for_selected_institution]
  self.solr_search_params_logic += [:for_selected_object]
  self.solr_search_params_logic += [:for_selected_file]
  self.solr_search_params_logic += [:sort_chronologically]

  def index
    if params['institution_id']
      @institution = Institution.find(params['institution_id'])
      obj = @institution
    elsif params['intellectual_object_id']
      @intellectual_object = IntellectualObject.find(params['intellectual_object_id'])
      obj = @intellectual_object
    elsif params['generic_file_id']
      @generic_file = GenericFile.find(params['generic_file_id'])
      obj = @generic_file
    end
    authorize obj
    respond_to do |format|
      format.json { render json: obj.premisEvents.events.map { |event| event.serializable_hash } }
      # TODO: Code review. Can't get the HTML rendering to work without super,
      # but do I really want to call super within this block???
      format.html {super}
    end
  end

  def create
    @event = @parent_object.add_event(params['event'])
    respond_to do |format|
      format.json {
        if @parent_object.save
          render json: @event.serializable_hash, status: :created
        else
          render json: @event.errors, status: :unprocessable_entity
        end
      }
      format.html {
        if @parent_object.save
          flash[:notice] = "Successfully created new event: #{@event.identifier}"
        else
          flash[:alert] = "Unable to create event for #{@parent_object.id} using input parameters: #{params['event']}"
        end
        redirect_to @parent_object
      }
    end
  end

  #def search_action_url *args
  #  catalog_index_url *args
  #end

protected

  def inst_id_exists?
    params['institution_id']
  end

  def intellectual_object_id_exists?
    params['intellectual_object_id']
  end

  def generic_file_id_exists?
    params['generic_file_id']
  end

  def intellectual_object_identifier_exists?
    params['intellectual_object_identifier']
  end

  def generic_file_identifier_exists?
    params['generic_file_identifier']
  end

  def load_intellectual_object
    objId = params[:intellectual_object_identifier].gsub(/%2F/i, '/')
    @parent_object = IntellectualObject.where(desc_metadata__identifier_ssim: objId).first
    params[:intellectual_object_id] = @parent_object.id
  end

  # Loads the generic file to which the event being created is related.
  # In dev environment, using WebBrick, converting '%2F' to '/' is not
  # necessary, but it is required when running under Apache + Passenger,
  # because they leave the '%2F' unescaped.
  def load_generic_file
    gfid = params[:generic_file_identifier].gsub(/%2F/i, '/')
    @parent_object = GenericFile.where(tech_metadata__identifier_ssim: gfid).first
    params['generic_file_id'] = @parent_object.id
  end

  def load_and_authorize_parent_object
    if @parent_object.nil?
      parent_id = params['generic_file_id'] || params['intellectual_object_id']
      @parent_object = ActiveFedora::Base.find(parent_id)
    end
    authorize @parent_object, :add_event?
  end

  def for_selected_institution(solr_parameters, user_parameters)
    return unless @institution
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "institution_id_ssim:\"#{@institution.id}\""
  end

  def for_selected_object(solr_parameters, user_parameters)
    return unless @intellectual_object
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "intellectual_object_id_ssim:\"#{@intellectual_object.id}\""
  end

  def for_selected_file(solr_parameters, user_parameters)
    return unless @generic_file
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "generic_file_id_ssim:\"#{@generic_file.id}\""
  end

  def only_events(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "event_type_ssim:*"
  end

  def sort_chronologically(solr_parameters, user_parameters)
    chron_sort = "#{Solrizer.solr_name('event_date_time', :sortable)} desc"

    unless solr_parameters[:sort].blank?
      chron_sort = chron_sort + ', ' + solr_parameters[:sort]
    end

    solr_parameters[:sort] = chron_sort
  end

  def event_params
    params.require(:intellectual_object).permit(
                :identifier,
                :type,
                :outcome,
                :outcome_detail,
                :outcome_information,
                :date_time,
                :detail,
                :object,
                :agent)
  end

end
