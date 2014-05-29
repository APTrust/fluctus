class ProcessedItemController < ApplicationController
  inherit_resources
  before_filter :set_items, only: :index
  before_filter :set_item, only: :show

  def create
    respond_to do |format|
      if resource.save
        format.json { render json: @processed_item, status: :created }
      else
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @json_item = @processed_item.to_json
  end

  private

  def set_items
    @institution = current_user.institution
    @processed_items = ProcessedItem.where(institution: @institution.name)
    if(@institution.name == "APTrust")
      @processed_items = ProcessedItem.all()
    end
    params[:id] = @institution.id
    puts "count: #{@processed_items.count}"
  end

  def set_item
    @institution = current_user.institution
    @processed_item = ProcessedItem.where(etag: params[:etag], name: params[:name])
    params[:id] = @processed_item.id
  end
end
