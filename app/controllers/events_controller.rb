class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_and_authorize_parent_object, only: [:create]
  before_filter :load_and_authorize_intellectual_object, only: [:index], if: :intellectual_object_id_exists?
  #load_and_authorize_resource :intellectual_object, only: [:index], if: :intellectual_object_id_exists?
  before_filter :load_and_authorize_institution, only: [:index], if: :inst_id_exists?
  #load_and_authorize_resource :institution, only: [:index], if: :inst_id_exists?

  include Aptrust::GatedSearch

  self.solr_search_params_logic += [:only_events]
  self.solr_search_params_logic += [:for_selected_institution]
  self.solr_search_params_logic += [:for_selected_object]
  self.solr_search_params_logic += [:sort_chronologically]

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

  def inst_id_exists?
    params['institution_identifier']
  end

  def intellectual_object_id_exists?
    params['intellectual_object_identifier']
  end

  def load_and_authorize_parent_object
    #parent_id = params['generic_file_id'] || params['intellectual_object_id']
    if params['intellectual_object_identifier'].nil?
      @parent_object = ActiveFedora::Base.find(params['generic_file_id'])
    else
      io_options = IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: params[:intellectual_object_identifier])
      io_options.each do |io|
        if params[:intellectual_object_identifier] == io.intellectual_object_identifier
          @parent_object = io
        end
      end
    end
    #@parent_object = ActiveFedora::Base.find(parent_id)
    authorize! :update, @parent_object
  end

  def load_and_authorize_intellectual_object
    io_options = IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: params[:intellectual_object_identifier])
    io_options.each do |io|
      if params[:intellectual_object_identifier] == io.intellectual_object_identifier
        @intellectual_object = io
      end
    end
    authorize! params[:action].to_sym, @intellectual_object
  end

  def load_and_authorize_institution
    @institution = Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).first
    authorize! params[:action].to_sym, @institution
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

end
