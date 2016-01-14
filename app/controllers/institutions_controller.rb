class InstitutionsController < ApplicationController
  inherit_resources
  before_filter :authenticate_user!
  before_action :load_institution, only: [:edit, :update, :show, :destroy]
  respond_to :json, :html

  after_action :verify_authorized, :except => :index
  after_action :verify_policy_scoped, :only => :index

  def index
    respond_to do |format|
      @institutions = policy_scope(Institution)
      @sizes = find_all_sizes
      format.json { render json: @institutions.map { |inst| inst.serializable_hash } }
      format.html { render 'index' }
    end
  end

  def api_index
    @institution = current_user.institution
    authorize @institution, :index?
    if current_user.admin?
      params[:institution].present? ? @items = IntellectualObject.where(is_part_of: params[:institution]) : @items = IntellectualObject.all
    else
      @items = IntellectualObject.where(is_part_of: current_user.institution.identifier)
    end
    @items = @items.where(identifier: params[:name_exact]) if params[:name_exact].present?
    @items = @items.where(desc_metadata__identifier_tesim: params[:name_contains]) if params[:name_contains].present?
    date = format_date if params[:updated_since].present?
    @items = @items.where(:modified_date >= date) if params[:updated_since].present?
    @count = @items.count
    params[:page].present? ? page = params[:page] : page = 1
    params[:per_page].present? ? per_page = params[:per_page] : per_page = 10
    @items = @items.page(page).per(per_page)
    @next = format_next
    @previous = format_previous
    render json: {count: @count, next: @next, previous: @previous, results: [@items.map{ |item| item.serializable_hash}]}
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
    authorize @institution || Institution.new
    if @institution.nil? || @institution.state == 'D'
      respond_to do |format|
        format.json {render :nothing => true, :status => 404}
        format.html {
          redirect_to root_path
          flash[:alert] = 'The institution you requested does not exist or has been deleted.'
        }
      end
    else
      set_recent_objects
      respond_to do |format|
        format.json { render json: @institution }
        format.html
      end
    end
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
    def load_institution
      @institution = params[:institution_identifier].nil? ? current_user.institution : Institution.where(desc_metadata__identifier_ssim: params[:institution_identifier]).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def build_resource_params
      params[:action] == 'new' ? [] : [params.require(:institution).permit(:name, :identifier, :brief_name, :dpn_uuid)]
    end

    def set_recent_objects
      if current_user.admin? && current_user.institution.identifier == @institution.identifier
        @items = ProcessedItem.order('date').limit(10).reverse_order
        @size = GenericFile.bytes_by_format['all']
        @item_count = ProcessedItem.all.count
        @object_count = IntellectualObject.all.count
      else
        @items = ProcessedItem.where(institution: @institution.identifier).order('date').limit(10).reverse_order
        @size = @institution.bytes_by_format()['all']
        @item_count = ProcessedItem.where(institution: @institution.identifier).count
        @object_count = @institution.intellectual_objects.count
      end
      @failed = @items.where(status: Fluctus::Application::FLUCTUS_STATUSES['fail'])
    end

    def find_all_sizes
      size = {}
      total_size = 0
      Institution.all.each do |inst|
        size[inst.name] = inst.bytes_by_format()['all']
        total_size = size[inst.name] + total_size
      end
      size['APTrust'] = total_size
      size
    end

    def format_date
      date = Date.parse(params[:updated_since]).
      date.change(:usec => 0)
      date
    end

    def format_next
      if @count.to_f / params[:per_page] <= params[:page]
        nil
      else
        params[:page] = params[:page] + 1
        new_url = "https://repository.aptrust.org/member-api/v1/objects/?page=#{params[:page]}&page_size=#{params[:per_page]}"
        new_url = add_params(new_url)
        new_url
      end
    end

    def format_previous
      if params[:page] == 1
        nil
      else
        params[:page] = params[:page] - 1
        new_url = "https://repository.aptrust.org/member-api/v1/objects/?page=#{params[:page]}&page_size=#{params[:per_page]}"
        new_url = add_params(new_url)
        new_url
      end
    end

    def add_params(str)
      str = str << "&updated_since=#{params[:updated_since]}" if params[:updated_since].present?
      str = str << "&name_exact=#{params[:name_exact]}" if params[:name_exact].present?
      str = str << "&name_contains=#{params[:name_contains]}" if params[:name_contains].present?
      str = str << "&institution=#{params[:institution]}" if params[:institution].present?
      str
    end
end
