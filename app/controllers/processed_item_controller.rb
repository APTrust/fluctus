class ProcessedItemController < ApplicationController
  respond_to :html, :json
  inherit_resources
  load "config/pid_map.rb"
  load "processed_item_helper.rb"
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

  def handle_selected
    review_list = params[:review]
    purge_list = params[:purge]
    unless review_list.nil?
      review_list.each do |item|
        id = item.split("_")[1]
        proc_item = ProcessedItem.find(id)
        proc_item.reviewed = true;
        proc_item.save!
      end
    end
    unless purge_list.nil?
      purge_list.each do |item|
        id = item.split("_")[1]
        proc_item = ProcessedItem.find(id)
        proc_item.reviewed = true;
        proc_item.purge = true;
        proc_item.save!
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
      item.reviewed = true;
      item.save!
    end
    redirect_to :back
    flash[:notice] = 'All items have been marked as reviewed.'
  end

  def purge_all
    institution_bucket = 'aptrust.receiving.'+ current_user.institution.identifier
    items = ProcessedItem.where(bucket: institution_bucket, status: "Failed")
    if(current_user.admin?)
      items = ProcessedItem.where(status: "Failed")
    end
    items.each do |item|
      item.reviewed = true;
      item.purge = true;
      item.save!
    end
    redirect_to :back
    flash[:notice] = 'All failed items have been marked for purge from the S3 receiving bucket.'
  end


  private

  def init_from_params
    @processed_item = ProcessedItem.new(processed_item_params)
    @processed_item.user = current_user.email
  end

  def find_and_update
    # Parse date explicitly, or ActiveRecord will not find records when date format string varies.
    bag_date = Time.parse(params[:bag_date])
    @processed_item = ProcessedItem.where(name: params[:name], etag: params[:etag], bag_date: bag_date).first
    if @processed_item
      @processed_item.update(processed_item_params)
      @processed_item.user = current_user.email
    end
  end

  def set_filter_values
    @statuses = ['Succeeded', 'Processing', 'Failed']
    @stages = ['Fetch', 'Unpack', 'Validate', 'Store', 'Record']
    @actions = ['Ingest', 'Fixity Check', 'Retrieval', 'Deletion']
    @institutions = Array.new
    Institution.all.each do |inst|
      @institutions.push(inst.identifier) unless inst.identifier == 'aptrust.org'
    end
  end

  def processed_item_params
    params.require(:processed_item).permit(:name, :etag, :bag_date, :bucket,
                                           :institution, :date, :note, :action,
                                           :stage, :status, :outcome, :retry)
  end


  def set_items
    puts "Notice: #{session[:select_notice]}"
    unless (session[:select_notice].nil? || session[:select_notice] == "")
      flash[:notice] = session[:select_notice]
      session[:select_notice] = ""
    end
    @institution = current_user.institution
    institution_bucket = 'aptrust.receiving.'+ @institution.identifier
    @processed_items = ProcessedItem.where(bucket: institution_bucket, reviewed: false)
    if(@institution.name == 'APTrust')
      @processed_items = ProcessedItem.all()
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
    set_filter_values
  end

  # Users can hit the show route via /id or /etag/name/bag_date.
  # We have to find the item either way.
  def set_item
    @institution = current_user.institution
    if params[:id].blank? == false
      @processedItem = ProcessedItem.find(params[:id])
    else
      # Parse date explicitly, or ActiveRecord will not find records
      # when date format string varies.
      bag_date = Time.parse(params[:bag_date])
      @processed_item = ProcessedItem.where(etag: params[:etag],
                                            name: params[:name],
                                            bag_date: bag_date).first
      params[:id] = @processed_item.id if @processed_item
    end
  end
end
