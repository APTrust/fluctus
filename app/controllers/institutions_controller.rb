class InstitutionsController < ApplicationController
  inherit_resources
  before_filter :authenticate_user!
  before_action :set_institution, only: [:edit, :update, :show, :destroy]
  respond_to :json, :html

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
  end

  def create
    @institution = build_resource
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
    def set_institution
      @institution = params[:institution_identifier].nil? ? current_user.institution : Institution.where(desc_metadata__identifier_ssim: params[:institution_identifier]).first
      set_recent_objects
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def build_resource_params
      params[:action] == 'new' ? [] : [params.require(:institution).permit(:name, :identifier)]
    end

    def set_recent_objects
      if current_user.admin? && current_user.institution.identifier == @institution.identifier
        @items = ProcessedItem.order('date').limit(10).reverse_order
        @size = find_all_sizes
        @item_count = ProcessedItem.all.count
        @object_count = IntellectualObject.all.count
      else
        @items = ProcessedItem.where(institution: @institution.identifier).order('date').limit(10).reverse_order
        @size = find_size(@institution)
        @item_count = ProcessedItem.where(institution: @institution.identifier).count
        @object_count = @institution.intellectual_objects.count
      end
      @failed = @items.where(status: Fluctus::Application::FLUCTUS_STATUSES['fail'])
    end

    def find_size(institution)
      size = 0
      institution.intellectual_objects.each do |object|
        query = "id\:#{RSolr.escape(object.id)}"
        solr_result = ActiveFedora::SolrService.query(query).first
        new_size = solr_result['total_file_size_ssim'].nil? ? 0 : solr_result['total_file_size_ssim'].first
        size = size + new_size.to_i
      end
      size
    end

    def find_all_sizes
      size = {}
      total_size = 0
      Institution.all.each do |inst|
        current_size = find_size(inst)
        size[inst.name] = current_size
        total_size = current_size + total_size
      end
      size['APTrust'] = total_size
      size
    end
end
