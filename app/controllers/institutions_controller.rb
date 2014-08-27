class InstitutionsController < ApplicationController
  inherit_resources
  load_resource
  before_filter :authenticate_user!
  before_action :set_institution, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html

  # pundit ensures actions go through the authorization step
  # pundit ensures actions go through the authorization step
  after_action :verify_authorized, :except => :index
  after_action :verify_policy_scoped, :only => :index

  def index
    respond_to do |format|
      @institutions = policy_scope(Institution)
      format.json { render json: @institutions.map { |inst| inst.serializable_hash } }
      format.html { render "index" }
    end
  end

  def new
    @institution = Institution.new
    authorize @institution
    new!
  end

  def create
    authorize @institution
    create!
  end

  def show
    authorize @institution
    show!
  end

  def edit
    authorize @institution
    edit!
  end

  def update
    authorize @institution
    update!
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
