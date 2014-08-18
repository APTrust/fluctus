class InstitutionsController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_institution, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html

  # pundit ensures actions go through the authorization step
  after_filter :verify_authorized

  def index
    respond_to do |format|
      #@institutions = collection
      format.json { render json: collection.map { |inst| inst.serializable_hash } }
      @institutions = policy_scope(Institution)
      format.html { render "index" }
    end
  end

  def show
    authorize @institution
    respond_to do |format|
      format.json { render json: object_as_json }
      format.html { render "show" }
    end
  end

  include Blacklight::SolrHelper

  private
    # If an id is passed through params, use it.  Otherwise default to show a current user's institution.
    def set_institution
      @institution = params[:id].nil? ? current_user.institution : Institution.find(params[:id])
      set_recent_objects
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def build_resource_params
      params[:action] == 'new' ? [] : [params.require(:institution).permit(:name, :identifier)]
    end

    def set_recent_objects
      if (current_user.admin? && current_user.institution.identifier == @institution.identifier)
        @items = ProcessedItem.order('date').limit(10).reverse_order
      else
        @items = ProcessedItem.where(institution: @institution.identifier).order('date').limit(10).reverse_order
      end
      @failed = @items.where(status: Fluctus::Application::FLUCTUS_STATUSES['fail'])
    end
end
