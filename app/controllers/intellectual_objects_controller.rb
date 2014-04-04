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

  def show
    puts "This is the show action.------------------------------------------------------------------"
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
    #puts "In for_selected_institution------------------------------------------"
    #puts params[:institution_identifier]
    #puts params[:intellectual_object_identifier]
    if(params[:institution_identifier])
      institution = Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).first
    else
      io = IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: params[:intellectual_object_identifier]).first
      institution = io.institution
    end
    #puts "INSTITUTION: #{institution.id}"
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{institution.id}")
  end

  # Override Blacklight so that it has the "institution_identifier" set even when we're on a show page (e.g. /objects/foo:123)
  def search_action_url options = {}
    institution_intellectual_objects_path(params[:institution_identifier] || @intellectual_object.institution.institution_identifier)
  end

  def set_institution
    if params[:institution_identifier].nil? || Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).empty?
      redirect_to root_url
      flash[:alert] = "Sonething wrong with institution_identifier."
    else
      @institution = Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).first
      authorize! [:index], @institution if cannot? :read, @institution
      if current_user.institutional_admin?
        authorize! [:create], @institution if cannot? :edit, @institution
      end
    end
  end

  def set_object
    #puts "Inst: #{params[:institution_identifier]}, IntObj: #{params[:intellectual_object_identifier]}--------------------------"
    #identifier = "#{params[:institution_identifier]}/#{params[:intellectual_object_identifier]}"
    if params[:intellectual_object_identifier].nil?
      redirect_to root_url
      flash[:alert] = "Nil Identifier."
    elsif IntellectualObject.where(desc_metadata__intellectual_object_identifier_tesim: params[:intellectual_object_identifier]).empty?
      redirect_to root_url
      flash[:alert] = "Empty Array."
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
      #puts "I have INTOBJ with identifier: #{@intellectual_object.intellectual_object_identifier}"
      authorize! [:show], @intellectual_object if cannot? :read, @intellectual_object
      if current_user.institutional_user? || current_user.institutional_admin?
        authorize! [:edit, :update, :destroy], @intellectual_object if cannot? :edit, @intellectual_object
      end
    end
  end
end
