class IntellectualObjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_institution, only: [:index, :create]
  before_filter :set_intellectual_object, except: [:index, :create]

  include Aptrust::GatedSearch
  apply_catalog_search_params
  include RecordsControllerBehavior

  self.solr_search_params_logic += [:for_selected_institution]

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

  protected

  # Override Hydra-editor to redirect to an alternate location after create
  def redirect_after_update
    intellectual_object_path(resource)
  end

  def self.cancan_resource_class
    CanCan::ControllerResource
  end

  private

  def set_institution
    @institution = Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).first
    authorize! params[:action].to_sym, @institution
  end

  # Convienence method for pulling back the intellectual object by
  def set_intellectual_object
    @intellectual_object = IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: params[:intellectual_object_identifier]).first
    @institution = @intellectual_object.institution
    authorize! params[:action].to_sym, @intellectual_object
  end

  # Set the search params for the page return based on the insitution.
  def for_selected_institution(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{@institution.id}")
  end

  # Override Blacklight so that it has the "institution_identifier" set even when we're on a show page (e.g. /objects/foo:123)
  def search_action_url options = {}
    institution_intellectual_objects_path(params[:institution_identifier] || @intellectual_object.institution.institution_identifier)
  end
end