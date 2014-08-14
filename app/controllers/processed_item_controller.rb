class ProcessedItemController < ApplicationController
  respond_to :html, :json
  inherit_resources
  before_filter :authenticate_user!
  before_filter :set_items, only: :index
  before_filter :set_item, only: :show
  before_filter :init_from_params, only: :create
  before_filter :find_and_update, only: :update

  def create
    respond_to do |format|
      if @processed_item.save
        format.json { render json: @processed_item, status: :created }
      else
        format.json { render json: @processed_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @processed_item.save
        format.json { render json: @processed_item, status: :created }
      else
        format.json { render json: @processed_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # This is an API call for the bucket reader that queues up work for
  # the bag processor. It returns all of the items that have started
  # the ingest process since the specified timestamp.
  def ingested_since
    since = params[:since]
    begin
      dtSince = DateTime.parse(since)
    rescue
      # We'll get this below
    end
    respond_to do |format|
      if dtSince == nil
        err = { 'error' => 'Param since must be a valid datetime' }
        format.json { render json: err, status: :bad_request }
      else
        @items = ProcessedItem.where("action='Ingest' and date >= ?", dtSince)
        format.json { render json: @items, status: :ok }
      end
    end
  end

  # get '/api/v1/itemresults/restore'
  # Returns a list of items the users have requested
  # to be queued for restoration.
  def restore
    restore = Fluctus::Application::FLUCTUS_ACTIONS['restore']
    requested = Fluctus::Application::FLUCTUS_STAGES['requested']
    pending = Fluctus::Application::FLUCTUS_STATUSES['pend']
    @items = ProcessedItem.where(action: restore, stage: requested, status: pending)
    if(current_user.admin? == false)
      @items = @items.where(institution: current_user.institution.identifier)
    end
    respond_to do |format|
      format.json { render json: @items, status: :ok }
    end
  end

  def show_reviewed
    session[:show_reviewed] = params[:show]
    respond_to do |format|
      format.js {}
    end
  end

  # This is an API call. The Go code will periodically get a list
  # of reviewed items and delete the original uploaded files
  # from the reveiving bucket.
  def get_reviewed
    @items = ProcessedItem.where(reviewed: true)
    if(current_user.admin? == false)
      @items = @items.where(institution: current_user.institution.identifier)
    end
    respond_to do |format|
      format.json { render json: @items, status: :ok }
    end
  end


  def handle_selected
    review_list = params[:review]
    unless review_list.nil?
      review_list.each do |item|
        id = item.split("_")[1]
        proc_item = ProcessedItem.find(id)
        if (proc_item.status == Fluctus::Application::FLUCTUS_STATUSES['success'] || proc_item.status == Fluctus::Application::FLUCTUS_STATUSES['fail'])
          proc_item.reviewed = true
          proc_item.save!
        end
      end
    end
    set_items
    session[:select_notice] = 'Selected items have been marked for review or purge from S3 as indicated.'
    respond_to do |format|
      format.js {}
    end
  end

  def review_all
    institution_bucket = 'aptrust.receiving.'+ current_user.institution.identifier
    items = ProcessedItem.where(bucket: institution_bucket)
    if(current_user.admin?)
      items = ProcessedItem.all()
    end
    items.each do |item|
      if (item.date < session[:purge_datetime] && (item.status == Fluctus::Application::FLUCTUS_STATUSES['success'] || item.status == Fluctus::Application::FLUCTUS_STATUSES['fail']))
        item.reviewed = true
        item.save!
      end
    end
    session[:purge_datetime] = Time.now.utc
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to root_path
    flash[:notice] = 'All items have been marked as reviewed.'
  end

  private

  def init_from_params
    @processed_item = ProcessedItem.new(processed_item_params)
    @processed_item.user = current_user.email
  end

  def find_and_update
    # Parse date explicitly, or ActiveRecord will not find records when date format string varies.
    set_item
    if @processed_item
      @processed_item.update(processed_item_params)
      @processed_item.user = current_user.email
    end
  end

  def set_filter_values
    @statuses = Fluctus::Application::FLUCTUS_STATUSES.values
    @stages = Fluctus::Application::FLUCTUS_STAGES.values
    @actions = Fluctus::Application::FLUCTUS_ACTIONS.values
    @institutions = Array.new
    Institution.all.each do |inst|
      @institutions.push(inst.identifier) unless inst.identifier == 'aptrust.org'
    end
  end

  def processed_item_params
    params.require(:processed_item).permit(:name, :etag, :bag_date, :bucket,
                                           :institution, :date, :note, :action,
                                           :stage, :status, :outcome, :retry, :reviewed)
  end


  def set_items
    unless (session[:select_notice].nil? || session[:select_notice] == "")
      flash[:notice] = session[:select_notice]
      session[:select_notice] = ""
    end
    @institution = current_user.institution
    if(session[:show_reviewed] == 'true')
      @processed_items = ProcessedItem.where(institution: @institution.identifier).order('date').reverse_order
    else
      @processed_items = ProcessedItem.where(institution: @institution.identifier, reviewed: false).order('date').reverse_order
    end
    if current_user.admin?
      @processed_items = ProcessedItem.order('date').reverse_order
    end
    @filtered_items = @processed_items
    if params[:status].present?
      @filtered_items = @processed_items.where(status: params[:status])
      @selected = params[:status]
    end
    if params[:stage].present?
      @filtered_items = @processed_items.where(stage: params[:stage])
      @selected = params[:stage]
    end
    if params[:actions].present?
      @filtered_items = @processed_items.where(action: params[:actions])
      @selected = params[:actions]
    end
    if params[:institution].present?
      @filtered_items = @processed_items.where(institution: params[:institution])
      @selected = params[:institution]
    end
    params[:id] = @institution.id
    @items = @filtered_items.page(params[:page]).per(10)
    session[:purge_datetime] = Time.now.utc if params[:page] == 1 || params[:page].nil?
    set_filter_values
  end

  # Users can hit the show route via /id or /etag/name/bag_date.
  # We have to find the item either way.
  def set_item
    @institution = current_user.institution
    if params[:id].blank? == false
      @processedItem = ProcessedItem.find(params[:id])
    else
      if Rails.env.test? || Rails.env.development?
        set_item_sqlite
      else
        @processed_item = ProcessedItem.where(etag: params[:etag],
                                              name: params[:name],
                                              bag_date: params[:bag_date]).first
      end
      params[:id] = @processed_item.id if @processed_item
    end
  end

  # SQLite is f***ed up with date times, since it saves them as strings,
  # and the nanoseconds are wrong. We have to pull records out and do our
  # own time comparison.
  def set_item_sqlite
    bag_date = Time.parse(params[:bag_date])
    items = ProcessedItem.where(etag: params[:etag],
                                  name: params[:name])
    pattern = "%Y-%m-%d %H:%M:%S %Z"
    @processed_item = items.select { |item|
      bag_date.utc.strftime(pattern) == item.bag_date.utc.strftime(pattern)
    }.first
  end
end
