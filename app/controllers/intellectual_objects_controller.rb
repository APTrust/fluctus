class IntellectualObjectsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :institution, only: [:index, :create]
  load_and_authorize_resource :through => :institution, only: :create
  load_and_authorize_resource except: [:index, :create]

  include Aptrust::GatedSearch
  include RecordsControllerBehavior

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

  def for_selected_institution(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{params[:institution_id]}")
  end

  # Override Blacklight so that it has the "institution_id" set even when we're on a show page (e.g. /objects/foo:123)
  def search_action_url options = {}
    institution_intellectual_objects_path(params[:institution_id] || @intellectual_object.institution_id)
  end
end
