class IntellectualObjectsController < ApplicationController
  before_filter :authenticate_user!
  #load_and_authorize_resource :institution, only: [:index, :create]
  #load_and_authorize_resource :through => :institution, only: :create
  #load_and_authorize_resource except: [:index, :create]
  before_filter :set_object, only: [:show, :edit, :update, :destroy]
  before_filter :set_institution, only: [:index, :create]

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

  def for_selected_institution(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{params[:institution_id]}")
  end

  # Override Blacklight so that it has the "institution_identifier" set even when we're on a show page (e.g. /objects/foo:123)
  def search_action_url options = {}
    institution_intellectual_objects_path(params[:institution_identifier] || @intellectual_object.institution_identifier)
  end

  def set_institution
    if params[:institution_identifier].nil? || Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).empty?
      redirect_to root_url
      flash[:alert] = "Sonething wrong with institution_identifier."
    else
      puts "In the else statement in set_institution----------------------------------"
      @institution = Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).first
      #authorize! [:create, :index], @institution if cannot? :read, @institution
    end
  end

  def set_object
    if params[:intellectualobject_identifier].nil? || IntellectualObject.where(desc_metadata__intellectualobject_identifier_tesim: params[:intellectualobject_identifier]).empty?
      redirect_to root_url
      flash[:alert] = "Something wrong with intellectualobject_identifier."
    else
      @intellectual_object = IntellectualObject.where(desc_metadata__intellectualobject_identifier_tesim: params[:intellectualobject_identifier]).first
      #authorize! [:show, :edit, :update, :destroy], @institution if cannot? :read, @institution
    end
  end
end
