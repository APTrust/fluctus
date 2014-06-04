class ProcessedItemController < ApplicationController
  respond_to :html, :json
  inherit_resources
  load "config/pid_map.rb"
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


  def processed_item_params
    params.require(:processed_item).permit(:name, :etag, :bag_date, :bucket,
                                           :institution, :date, :note, :action,
                                           :stage, :status, :outcome)
  end


  def set_items
    @institution = current_user.institution
    institution_bucket = "aptrust.receiving."+ PID_MAP[@institution.name]
    @processed_items = ProcessedItem.where(bucket: institution_bucket)
    if(@institution.name == "APTrust")
      @processed_items = ProcessedItem.all()
    end
    params[:id] = @institution.id
    puts "count: #{@processed_items.count}"
    @items = @processed_items.page(params[:page]).per(10)
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
