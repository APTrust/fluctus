class IntellectualObjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_object, only: [:show, :edit, :update, :destroy]
  before_filter :set_institution, only: [:index, :create]

  include Aptrust::GatedSearch
  apply_catalog_search_params
  include RecordsControllerBehavior

  self.solr_search_params_logic += [:for_selected_institution]

  def update
    if params[:counter]
      search_session[:counter] = params[:counter]
      redirect_to :action => "show", :status => 303
    else
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
    if(params[:institution_identifier])
      institution = Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).first
    else
      io_options = IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: params[:intellectual_object_identifier])
      io_options.each do |io|
        if params[:intellectual_object_identifier] == io.intellectual_object_identifier
          intobj = io
          institution = intobj.institution
        end
      end
    end
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{institution.id}")
  end

  # Override Blacklight so that it has the "institution_identifier" set even when we're on a show page (e.g. /objects/foo:123)
  def search_action_url options = {}
    institution_intellectual_objects_path(params[:institution_identifier] || @intellectual_object.institution.institution_identifier)
  end

  def set_institution
    @institution = params[:institution_identifier].nil? ? current_user.institution : Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).first
    authorize! params[:action].to_sym, @institution
  end

  def set_object
    if params[:intellectual_object_identifier].nil? || IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: params[:intellectual_object_identifier]).empty?
      redirect_to root_url
      flash[:alert] = "Bad Identifier."
    else
      io_options = IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: params[:intellectual_object_identifier])
      io_options.each do |io|
        if params[:intellectual_object_identifier] == io.intellectual_object_identifier
          @intellectual_object = io
          @institution = @intellectual_object.institution
        end
      end
      if @intellectual_object.nil?
        redirect_to root_url
        flash[:alert] = "The object you requested does not exist."
      end
    end
    authorize! params[:action].to_sym, @intellectual_object
  end
end
