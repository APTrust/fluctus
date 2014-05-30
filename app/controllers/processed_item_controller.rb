class ProcessedItemController < ApplicationController
  respond_to :html, :json
  inherit_resources
  load "config/pid_map.rb"
  before_filter :authenticate_user!
  before_filter :set_items, only: :index
  before_filter :set_item, only: :show

  def create
    resource = ProcessedItem.new(processed_item_params)
    resource.user = current_user.email
    respond_to do |format|
      if resource.save
        format.json { render json: resource, status: :created }
      else
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end


  private

  def processed_item_params
    params.require(:processed_item).permit(:name, :etag, :bag_date, :bucket,
                                           :institution, :date, :note, :action,
                                           :stage, :status, :outcome)
  end


  def set_items
    @institution = current_user.institution
    institution_bucket = PID_MAP[@institution.pid]
    puts "BUCKET: #{institution_bucket}"
    @processed_items = ProcessedItem.where(institution: institution_bucket)
    if(@institution.name == "APTrust")
      @processed_items = ProcessedItem.all()
    end
    params[:id] = @institution.id
    puts "count: #{@processed_items.count}"
  end

  def set_item
    @institution = current_user.institution
    @processed_item = ProcessedItem.where(etag: params[:etag], name: params[:name]).first
    params[:id] = @processed_item.id if @processed_item
  end
end
