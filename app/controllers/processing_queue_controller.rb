class ProcessingQueueController < ApplicationController
  inherit_resources
  before_filter :set_queue

  private

  def set_queue
    @institution = current_user.institution
    @processing_queue = ProcessingQueue.new()
    @processing_queue.save
    @processing_queue.table = params[:json]
    params[:id] = @processing_queue.id
    if @institution.name == "APTrust"
      #don't filter, show all stuck items
    else
      #filter table by institution
    end
  end

end
