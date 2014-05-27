class ProcessingQueueController < ApplicationController
  inherit_resources
  before_filter :set_institution

  private

  def set_institution
    @institution = current_user.institution
    @processing_queue = ProcessingQueue.first
    @processing_queue.table = params[:json].table
    params[:id] = @processing_queue.id
    if @institution.name == "APTrust"
      #don't filter, show all stuck items
    else
      #filter table by institution
    end
  end

end
