class ProcessedItemController < ApplicationController
  respond_to :html, :json
  before_filter :authenticate_user!
  before_filter :set_items, only: :index
  before_filter :set_item, only: :show
  before_filter :init_from_params, only: :create
  before_filter :find_and_update, only: :update

  after_action :verify_authorized, :except => [:delete_test_items, :show_reviewed, :ingested_since]

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

  # Show for all by admin API. Don't show :state, :node, :pid in json to non-admin users.
  # The HTML template includes logic to show those attributes to APTrust admin,
  # but not to other users.
  def show
    authorize @processed_item
    respond_to do |format|
      if current_user.admin?
        item = @processed_item.serializable_hash
      else
        item = @processed_item.serializable_hash(except: [:state, :node, :pid])
      end
      format.json { render json: item }
      format.html
    end
  end

  # Show for admin API users. Includes :state, :node, :pid
  def api_show
    @processed_item = ProcessedItem.find(params[:id])
    authorize @processed_item, :admin_show?
    respond_to do |format|
      format.json { render json: @processed_item }
      format.html
    end
  end

  # Note that this method is available through the admin API, but is
  # not accessible to members. If we ever make it accessible to members,
  # we MUST NOT allow them to update :state, :node, or :pid!
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
    params[:pi_sort] = 'date' if params[:pi_sort].nil?
    current_user.admin? ? initial_items = ProcessedItem.all : initial_items = ProcessedItem.where(institution: @institution.identifier)
    authorize initial_items
    if field == 'Name'
      @processed_items = initial_items.where('name LIKE ?', search_param)
    elsif field == 'Etag'
      @processed_items = initial_items.where('etag LIKE ?', search_param)
    elsif params[:qq] == '*'
      @processed_items = initial_items
    else
      @processed_items = initial_items.where('name LIKE ? OR etag LIKE ?', search_param, search_param)
    end
    @processed_items = @processed_items.order(params[:pi_sort])
    @processed_items = @processed_items.reverse_order if params[:pi_sort] == 'date'
    filter_items
    set_filter_values
    params[:id] = @institution.id
    @items = @filtered_items.page(params[:page]).per(10)
    set_counts
    page_count
  end

  # /api/v1/itemresults/search
  # Allows the API client to pass in some very specific criteria
  def api_search
    current_user.admin? ? @items = ProcessedItem.all : @items = ProcessedItem.where(institution: current_user.institution.identifier)
    authorize @items, :admin_api?
    if Rails.env.test? || Rails.env.development?
      rewrite_params_for_sqlite
    end
    search_fields = [:name, :etag, :bag_date, :stage, :status, :institution,
                     :retry, :reviewed, :object_identifier, :generic_file_identifier,
                     :node, :needs_admin_review, :process_after]
    search_fields.each do |field|
      if params[field].present?
        if field == :bag_date && (Rails.env.test? || Rails.env.development?)
          @items = @items.where("datetime(bag_date) = datetime(?)", params[:bag_date])
        elsif field == :node and params[field] == "null"
          @items = @items.where("node is null")
        elsif field == :assignment_pending_since and params[field] == "null"
          @items = @items.where("assignment_pending_since is null")
        else
          @items = @items.where(field => params[field])
        end
      end
    end

    # Fix for Rails overwriting params[:action] with name of controller
    # action: Use param :item_action instead of :action
    if params[:item_action].present?
      @items = @items.where(action: params[:item_action])
    end
    respond_to do |format|
        format.json { render json: @items, status: :ok }
    end
  end

  def api_index
    if current_user.admin?
      params[:institution].present? ? @items = ProcessedItem.where(institution: params[:institution]) : @items = ProcessedItem.all
    else
      @items = ProcessedItem.where(institution: current_user.institution.identifier)
    end
    authorize @items, :index?
    @items = @items.where(name: params[:name_exact]) if params[:name_exact].present?

    # Do not instantiate objects. Let SQL do the filtering.
    if params[:name_contains].present?
      pattern = '%' + params[:name_contains] + '%'
      @items = @items.where('name LIKE ?', pattern)
    end

    # Do not instantiate objects. Let SQL do the filtering.
    if params[:updated_since].present?
      date = format_date
      @items = @items.where('updated_at >= ?', date)
    end

    @items = @items.where(action: Fluctus::Application::FLUCTUS_ACTIONS[params[:item_action]]) if params[:item_action].present?
    @items = @items.where(stage: Fluctus::Application::FLUCTUS_STAGES[params[:stage]]) if params[:stage].present?
    @items = @items.where(status: Fluctus::Application::FLUCTUS_STATUSES[params[:status]]) if params[:status].present?
    @items = @items.where(reviewed: to_boolean(params[:reviewed])) if params[:reviewed].present?
    @count = @items.count
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    @items = @items.page(page).per(per_page)
    @next = format_next(page, per_page)
    @previous = format_previous(page, per_page)
    json_list = @items.map { |item| item.serializable_hash(except: [:state, :node, :pid]) }
    render json: {count: @count, next: @next, previous: @previous, results: json_list}
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
        authorize @items, :admin_api?
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
    @items = @items.where(institution: current_user.institution.identifier) unless current_user.admin?
    authorize @items
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

  # get '/api/v1/itemresults/items_for_dpn'
  # Returns a list of items the users have requested
  # to be queued for DPN. These will always be
  # IntellectualObjects. If param object_identifier is supplied,
  # it returns all DPN requests for the object. Otherwise,
  # it returns pending requests for all objects where retry is true.
  # (This is because retry gets set to false when the requestor encounters
  # some fatal error. There is no sense in reprocessing those requests.)
  def items_for_dpn
    dpn = Fluctus::Application::FLUCTUS_ACTIONS['dpn']
    requested = Fluctus::Application::FLUCTUS_STAGES['requested']
    pending = Fluctus::Application::FLUCTUS_STATUSES['pend']
    @items = ProcessedItem.where(action: dpn)
    @items = @items.where(institution: current_user.institution.identifier) unless current_user.admin?
    authorize @items
    # Get items for a single object, which may consist of multiple bags.
    # Return anything for that object identifier with action=DPN and retry=true
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
    failed = Fluctus::Application::FLUCTUS_STATUSES['fail']
    @items = ProcessedItem.where(action: delete)
    @items = @items.where(institution: current_user.institution.identifier) unless current_user.admin?
    authorize @items
    # Return a record for a single file?
    if !request[:generic_file_identifier].blank?
      @items = @items.where(generic_file_identifier: request[:generic_file_identifier])
    else
      # If user is not looking for a single bag, return all requested items
      # where retry is true and status is pending or failed.
      @items = @items.where(stage: requested, status: [pending, failed], retry: true)
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
  # Since an item can be restored multiple times, we want to update
  # only the most recent restoration request for the item.
  #
  # Expects param :object_identifier in URL and :stage, :status, :retry
  # in post body.
  #
  # Should be available to admin user only.
  def set_restoration_status
    # Fix Apache/Passenger passthrough of %2f-encoded slashes in identifier
    params[:object_identifier] = params[:object_identifier].gsub(/%2F/i, "/")
    restore = Fluctus::Application::FLUCTUS_ACTIONS['restore']
    @item = ProcessedItem.where(object_identifier: params[:object_identifier],
                                 action: restore).order(created_at: :desc).first
    authorize @item || ProcessedItem.new  # avoids Pundit NilClass exception
    if @item
      succeeded = @item.update_attributes(params_for_status_update)
    end
    respond_to do |format|
      if @item.nil?
        error = { error: "No items for object identifier #{params[:object_identifier]}" }
        format.json { render json: error, status: :not_found }
      end
      if succeeded == false
        errors = @item.errors.full_messages
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
    current_user.admin? ? items = ProcessedItem.all : items = ProcessedItem.where(institution: current_user.institution.identifier)
    authorize items
    items.each do |item|
      if item.date < session[:purge_datetime] && (item.status == Fluctus::Application::FLUCTUS_STATUSES['success'] || item.status == Fluctus::Application::FLUCTUS_STATUSES['fail'])
        item.reviewed = true
        item.save!
      end
    end
    session[:purge_datetime] = Time.now.utc
    redirect_to :back
    flash[:notice] = 'All items have been marked as reviewed.'
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
    if params[:item_action].present?
      @filtered_items = @filtered_items.where(action: params[:item_action])
      @selected[:item_action] = params[:item_action]
    end
    if params[:institution].present?
      @filtered_items = @filtered_items.where(institution: params[:institution])
      @selected[:institution] = params[:institution]
    end
  end

  def page_count
    @total_number = @filtered_items.count
    if @total_number == 0
      @second_number = 0
      @first_number = 0
    elsif params[:page].nil?
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
                                           :stage, :status, :outcome, :retry, :reviewed,
                                           :state, :node)
  end

  def params_for_status_update
    params.permit(:object_identifier, :stage, :status, :note, :retry,
                  :state, :node, :pid, :needs_admin_review)
  end

  def set_items
    unless (session[:select_notice].nil? || session[:select_notice] == '')
      flash[:notice] = session[:select_notice]
      session[:select_notice] = ''
    end
    @institution = current_user.institution
    params[:pi_sort] = 'date' if params[:pi_sort].nil?
    (session[:show_reviewed] == 'true') ? @processed_items = ProcessedItem.where(institution: @institution.identifier).order(params[:pi_sort]) :
        @processed_items = ProcessedItem.where(institution: @institution.identifier, reviewed: false).order(params[:pi_sort])
    @processed_items = ProcessedItem.order(params[:pi_sort]) if current_user.admin?
    @processed_items = @processed_items.reverse_order if params[:pi_sort] == 'date'
    filter_items
    set_filter_values
    params[:id] = @institution.id
    @items = @filtered_items.page(params[:page]).per(10)
    authorize @items, :index?
    set_counts
    page_count
    session[:purge_datetime] = Time.now.utc if params[:page] == 1 || params[:page].nil?
  end

  # Sets the count for each status/stage/action/institution.
  # Assumes @items has been set first.
  def set_counts
    items = @filtered_items || @processed_items
    @counts = {}
    @statuses.each do |status|
      @counts[status] = items.where(status: status).count()
    end
    @stages.each do |stage|
      @counts[stage] = items.where(stage: stage).count()
    end
    @actions.each do |action|
      @counts[action] = items.where(action: action).count()
    end
    @institutions.each do |institution|
      @counts[institution] = items.where(institution: institution).count()
    end
  end

  # Users can hit the show route via /id or /etag/name/bag_date.
  # We have to find the item either way.
  def set_item
    @institution = current_user.institution
    if Rails.env.test? || Rails.env.development?
      rewrite_params_for_sqlite
    end
    if params[:id].blank? == false
      @processed_item = ProcessedItem.find(params[:id])
    else
      if Rails.env.test? || Rails.env.development?
        # Cursing ActiveRecord + SQLite. SQLite has all the milliseconds wrong!
        @processed_item = ProcessedItem.where(etag: params[:etag],
                                              name: params[:name])
        @processed_item = @processed_item.where('datetime(bag_date) = datetime(?)', params[:bag_date]).first
      else
      @processed_item = ProcessedItem.where(etag: params[:etag],
                                            name: params[:name],
                                            bag_date: params[:bag_date]).first
      end
    end
    if @processed_item
      params[:id] = @processed_item.id
    else
      # API callers **DEPEND** on getting a 404 if the record does
      # not exist. This is how they know that an item has not started
      # the ingestion process. So if @processed_item is nil, return
      # 404 now. Otherwise, the call to authorize below will result
      # in a 500 error from pundit.
      raise ActiveRecord::RecordNotFound
    end
    authorize @processed_item, :show?
  end

  def rewrite_params_for_sqlite
    # SQLite wants t or f for booleans
    if params[:retry].present? && params[:retry].is_a?(String)
        params[:retry] = params[:retry][0]
    end
    if params[:reviewed].present? && params[:retry].is_a?(String)
      params[:reviewed] = params[:reviewed][0]
    end
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def to_boolean(str)
    str == 'true'
  end

  def format_next(page, per_page)
    if @count.to_f / per_page <= page
      nil
    else
      new_page = page + 1
      new_url = "#{request.base_url}/member-api/v1/items/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous(page, per_page)
    if page == 1
      nil
    else
      new_page = page - 1
      new_url = "#{request.base_url}/member-api/v1/items/?page=#{new_page}&per_page=#{per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def add_params(str)
    str = str << "&updated_since=#{params[:updated_since]}" if params[:updated_since].present?
    str = str << "&name_exact=#{params[:name_exact]}" if params[:name_exact].present?
    str = str << "&name_contains=#{params[:name_contains]}" if params[:name_contains].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&actions=#{params[:item_action]}" if params[:item_action].present?
    str = str << "&stage=#{params[:stage]}" if params[:stage].present?
    str = str << "&status=#{params[:status]}" if params[:status].present?
    str = str << "&reviewed=#{params[:reviewed]}" if params[:reviewed].present?
    str = str << "&node=#{params[:node]}" if params[:node].present?
    str = str << "&reviewed=#{params[:needs_admin_review]}" if params[:needs_admin_review].present?
    str
  end

end
