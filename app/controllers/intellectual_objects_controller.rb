class IntellectualObjectsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :institution, only: [:index, :create]
  load_and_authorize_resource :through => :institution, only: :create
  load_and_authorize_resource except: [:index, :create]

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
    {
        pid: resource.pid,
        institution_id: resource.institution_id,
        title: resource.title,
        description: resource.description,
        access: resource.access,
        alt_identifier: resource.alt_identifier,
    }
  end

  def intellectual_object_params
    params.require(:intellectual_object).permit(:pid, :institution_id, :title,
                                                :description, :access,
                                                :alt_identifier)
  end

end
