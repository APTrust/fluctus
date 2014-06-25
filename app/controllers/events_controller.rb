class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_and_authorize_parent_object, only: [:create]
  load_and_authorize_resource :intellectual_object, only: [:index], if: :intellectual_object_id_exists?
  load_and_authorize_resource :institution, only: [:index], if: :inst_id_exists?
  load_and_authorize_resource :generic_file, only: [:index], if: :generic_file_id_exists?

  include Aptrust::GatedSearch

  self.solr_search_params_logic += [:only_events]
  self.solr_search_params_logic += [:for_selected_institution]
  self.solr_search_params_logic += [:for_selected_object]
  self.solr_search_params_logic += [:for_selected_file]
  self.solr_search_params_logic += [:sort_chronologically]

  def index
    respond_to do |format|
      obj = @generic_file.nil? ? @intellectual_object : @generic_file
      format.json { render json: obj.premisEvents.events.map { |event| event.serializable_hash } }
      # TODO: Code review. Can't get the HTML rendering to work without super,
      # but do I really want to call super within this block???
      format.html { super }
    end
  end

  def create
    @event = @parent_object.add_event(params['event'])
    respond_to do |format|
      format.json { render json: @event.serializable_hash, status: :created }
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

  def load_and_authorize_parent_object
    parent_id = params['generic_file_id'] || params['intellectual_object_id']
    @parent_object = ActiveFedora::Base.find(parent_id)
    authorize! :update, @parent_object
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
