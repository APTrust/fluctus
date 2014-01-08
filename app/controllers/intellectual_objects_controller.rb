class IntellectualObjectsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :institution, only: [:index, :create]
  load_and_authorize_resource :through => :institution, only: :create
  load_and_authorize_resource except: [:index, :create]

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Aptrust::AdminAccess
  include RecordsControllerBehavior

  # These before_filters apply the hydra access controls
  before_filter :enforce_show_permissions, only: :show

  copy_blacklight_config_from CatalogController
  self.solr_search_params_logic += [:add_access_controls_to_solr_params]
  self.solr_search_params_logic += [:only_intellectual_objects]
  self.solr_search_params_logic += [:for_selected_institution]

  def destroy
    resource.soft_delete
    respond_to do |format|
      format.json { head :no_content }
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

  # Limits search results just to IntellectualObjects
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-submitted parameters
  def only_intellectual_objects(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(has_model: IntellectualObject.to_class_uri)
  end

  def for_selected_institution(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{params[:institution_id]}")
  end

  # Override Blacklight so that it has the "institution_id" set even when we're on a show page (e.g. /objects/foo:123)
  def search_action_url options = {}
    institution_intellectual_objects_path(params[:institution_id] || @intellectual_object.institution_id)
  end
end
