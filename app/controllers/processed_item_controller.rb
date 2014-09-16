class ProcessedItemController < ApplicationController
  respond_to :html, :json
  before_filter :authenticate_user!
  before_filter :set_items, only: :index
  before_filter :set_item, only: :show
  before_filter :init_from_params, only: :create
  before_filter :find_and_update, only: :update

  after_action :verify_authorized, :except => [:index, :search, :get_reviewed, :review_all, :delete_test_items, :items_for_delete, :items_for_restore]
  
  def create
    authorize @processed_item
    respond_to do |format|
      if @processed_item.save
        format.json { render json: @processed_item, status: :created }
      else
        format.json { render json: @processed_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @processed_item
    respond_to do |format|
      if @processed_item.save
        format.json { render json: @processed_item, status: :ok }
      else
        format.json { render json: @processed_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def search
    search_param = "%#{params[:qq]}%"
    field = params[:pi_search_field]
    @institution = current_user.institution
    params[:sort] = 'date' if params[:sort].nil?
    if current_user.admin?
      if field == 'Name'
        @processed_items = ProcessedItem.where('name LIKE ?', search_param)
      elsif field == 'Etag'
        @processed_items = ProcessedItem.where('etag LIKE ?', search_param)
      elsif params[:qq] == '*'
        @processed_items = ProcessedItem.all
      else
        @processed_items = ProcessedItem.where('name LIKE ? OR etag LIKE ?', search_param, search_param)
      end
    else
      institution_items = ProcessedItem.where(institution: @institution.identifier)
      if field == 'Name'
        @processed_items = institution_items.where('name LIKE ?', search_param)
      elsif field == 'Etag'
        @processed_items = institution_items.where('etag LIKE ?', search_param)
      elsif params[:qq] == '*'
        @processed_items = institution_items
      else
        @processed_items = institution_items.where('name LIKE ? OR etag LIKE ?', search_param, search_param)
      end
    end
    @processed_items = @processed_items.order(params[:sort])
    @processed_items = @processed_items.reverse_order if params[:sort] == 'date'
    filter_items
    set_filter_values
    params[:id] = @institution.id
    @items = @filtered_items.page(params[:page]).per(10)
    page_count
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

  # get '/api/v1/itemresults/items_for_restore'
  # Returns a list of items the users have requested
  # to be queued for restoration. These will always be
  # IntellectualObjects. If param object_identifier is supplied,
  # it returns all restoration requests for the object. Otherwise,
  # it returns pending requests for all objects where retry is true.
  # (This is because retry gets set to false when the restorer encounters
  # some fatal error. There is no sense in reprocessing those requests.)
  def items_for_restore
    restore = Fluctus::Application::FLUCTUS_ACTIONS['restore']
    requested = Fluctus::Application::FLUCTUS_STAGES['requested']
    pending = Fluctus::Application::FLUCTUS_STATUSES['pend']
    @items = ProcessedItem.where(action: restore)
    if(current_user.admin? == false)
      @items = @items.where(institution: current_user.institution.identifier)
    end
    # Get items for a single object, which may consist of multiple bags.
    # Return anything for that object identifier with action=Restore and retry=true
    if !request[:object_identifier].blank?
      @items = @items.where(object_identifier: request[:object_identifier])
    else
      # If user is not looking for a single bag, return all requested/pending items.
      @items = @items.where(stage: requested, status: pending, retry: true)
    end
    respond_to do |format|
      format.json { render json: @items, status: :ok }
    end
  end


  # get '/api/v1/itemresults/items_for_delete'
  # Returns a list of items the users have requested
  # to be queued for deletion. These items will always represent
  # GenericFiles. If param generic_file_identifier is supplied,
  # it returns all deletion requests for the generic file. Otherwise,
  # it returns pending requests for all items where retry is true.
  # (This is because retry gets set to false when the restorer encounters
  # some fatal error. There is no sense in reprocessing those requests.)
  def items_for_delete
    delete = Fluctus::Application::FLUCTUS_ACTIONS['delete']
    requested = Fluctus::Application::FLUCTUS_STAGES['requested']
    pending = Fluctus::Application::FLUCTUS_STATUSES['pend']
    @items = ProcessedItem.where(action: delete)
    if(current_user.admin? == false)
      @items = @items.where(institution: current_user.institution.identifier)
    end
    # Return a record for a single file?
    if !request[:generic_file_identifier].blank?
      @items = @items.where(generic_file_identifier: request[:generic_file_identifier])
    else
      # If user is not looking for a single bag, return all requested/pending items.
      @items = @items.where(stage: requested, status: pending, retry: true)
    end
    respond_to do |format|
      format.json { render json: @items, status: :ok }
    end
  end


  # post '/api/v1/itemresults/delete_test_items'
  #
  # Integration tests from the Go code add some ProcessedItem records
  # that we'll want to delete. All have the institution test.edu.
  # The Go integration tests will call this method to clean up after
  # themselves. This method is forbidden in production.
  def delete_test_items
    respond_to do |format|
      if Rails.env.production?
        format.json { render json: {"error" => "This call is forbidden in production!"}, status: :forbidden }
      end
      ProcessedItem.where(institution: 'test.edu').delete_all
      format.json { render nothing: true, status: :ok }
    end
  end

  # post '/api/v1/itemresults/restoration_status/:object_identifier'
  #
  # This is an API call for the bag restoration service.
  #
  # Sets the status of items that the user has requested be restored.
  # A single object can have multiple bags and hence multiple processed
  # item records. When restorations starts, succeeds, or fails, we
  # need to update all processed items for that object at once.
  # We must update only those items that the user requested for restoration,
  # avoiding any older items that map to previous versions of the same
  # intellectual object, and avoiding newer items that may represent bags
  # that have not yet completed the ingest process.
  #
  # Expects param :object_identifier in URL and :stage, :status, :retry
  # in post body.
  #
  # Should be available to admin user only.
  def set_restoration_status
    # Fix Apache/Passenger passthrough of %2f-encoded slashes in identifier
    params[:object_identifier] = params[:object_identifier].gsub(/%2F/i, "/")
    @items = ProcessedItem.where(object_identifier: params[:object_identifier],
                                 action: Fluctus::Application::FLUCTUS_ACTIONS['restore'])
    authorize @items
    results = @items.map { |item| item.update_attributes(params_for_status_update) }
    respond_to do |format|
      if @items.count == 0
        error = { error: "No items for object identifier #{params[:object_identifier]}" }
        format.json { render json: error, status: :not_found }
      end
      if results.include?(false)
        errors = @items.first.errors.full_messages
        format.json { render json: errors, status: :bad_request }
      else
        format.json { render json: {result: 'OK'}, status: :ok }
      end
    end
  end

  def show_reviewed
    session[:show_reviewed] = params[:show_reviewed]
    respond_to do |format|
      format.js {}
    end
  end

  # This is an API call. The Go code will periodically get a list
  # of reviewed items and delete the original uploaded files
  # from the reveiving bucket.
  def get_reviewed
    @items = ProcessedItem.where(reviewed: true)
    unless current_user.admin?
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
        authorize proc_item, :mark_as_reviewed?
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
    if current_user.admin?
      items = ProcessedItem.all
      items.each do |item|
        if (item.date < session[:purge_datetime] && (item.status == Fluctus::Application::FLUCTUS_STATUSES['success'] || item.status == Fluctus::Application::FLUCTUS_STATUSES['fail']))
          item.reviewed = true
          item.save!
        end
      end
    else
      items = ProcessedItem.where(bucket: institution_bucket)
      items.each do |item|
        authorize item, :mark_as_reviewed?
        if (item.date < session[:purge_datetime] && (item.status == Fluctus::Application::FLUCTUS_STATUSES['success'] || item.status == Fluctus::Application::FLUCTUS_STATUSES['fail']))
          item.reviewed = true
          item.save!
        end
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

  def filter_items
    @filtered_items = @processed_items
    @selected = {}
    if params[:status].present?
      @filtered_items = @filtered_items.where(status: params[:status])
      @selected[:status] = params[:status]
    end
    if params[:stage].present?
      @filtered_items = @filtered_items.where(stage: params[:stage])
      @selected[:stage] = params[:stage]
    end
    if params[:actions].present?
      @filtered_items = @filtered_items.where(action: params[:actions])
      @selected[:actions] = params[:actions]
    end
    if params[:institution].present?
      @filtered_items = @filtered_items.where(institution: params[:institution])
      @selected[:institution] = params[:institution]
    end
  end

  def page_count
    @total_number = @filtered_items.count
    if params[:page].nil?
      @second_number = 10
      @first_number = 1
    else
      @second_number = params[:page].to_i * 10
      @first_number = @second_number.to_i - 9
    end
    @second_number = @total_number if @second_number > @total_number
  end

  def processed_item_params
    params.require(:processed_item).permit(:name, :etag, :bag_date, :bucket,
                                           :institution, :date, :note, :action,
                                           :stage, :status, :outcome, :retry, :reviewed)
  end

  def params_for_status_update
    params.permit(:object_identifier, :stage, :status, :note, :retry)
  end


  def set_items
    unless (session[:select_notice].nil? || session[:select_notice] == '')
      flash[:notice] = session[:select_notice]
      session[:select_notice] = ''
    end
    @institution = current_user.institution
    params[:sort] = 'date' if params[:sort].nil?
    if(session[:show_reviewed] == 'true')
      @processed_items = ProcessedItem.where(institution: @institution.identifier).order(params[:sort])
    else
      @processed_items = ProcessedItem.where(institution: @institution.identifier, reviewed: false).order(params[:sort])
    end
    @processed_items = ProcessedItem.order(params[:sort]) if current_user.admin?
    @processed_items = @processed_items.reverse_order if params[:sort] == 'date'
    filter_items
    set_filter_values
    params[:id] = @institution.id
    @items = @filtered_items.page(params[:page]).per(10)
    page_count
    session[:purge_datetime] = Time.now.utc if params[:page] == 1 || params[:page].nil?
  end

  # Users can hit the show route via /id or /etag/name/bag_date.
  # We have to find the item either way.
  def set_item
    @institution = current_user.institution
    if params[:id].blank? == false
      @processed_item = ProcessedItem.find(params[:id])
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
    authorize @processed_item, :show?
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
