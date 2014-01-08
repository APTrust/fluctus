class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_and_authorize_parent_object, only: [:create]
  load_and_authorize_resource :institution, only: [:index]

  include Aptrust::GatedSearch
  self.solr_search_params_logic += [:only_events]
  self.solr_search_params_logic += [:for_selected_institution]

  def create
    @event = @parent_object.add_event(params['event'])
    if @parent_object.save
      flash[:notice] = "Successfully created new event: #{@event.identifier}"
    else
      flash[:alert] = "Unable to create event for #{@parent_object.id} using input parameters: #{params['event']}"
    end
    redirect_to @parent_object
  end

protected

  def load_and_authorize_parent_object
    parent_id = params['generic_file_id'] || params['intellectual_object_id']
    @parent_object = ActiveFedora::Base.find(parent_id)
    authorize! :update, @parent_object
  end

  def for_selected_institution(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    id = ActiveFedora::SolrService.escape_uri_for_query(@institution.id)
    solr_parameters[:fq] << "institution_id_ssim:#{id}"
  end

  def only_events(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "event_type_ssim:*"
  end

end
