class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_and_authorize_parent_object

  def create
    @event = @parent_object.add_event(params['event'])
    if @parent_object.save
      flash[:notice] = "Successfully created new event: #{@event.identifier}"
    else
      flash[:alert] = "Unable to create event for #{@parent_object.id} using input parameters: #{params['event']}"
    end
    redirect_to @parent_object
  end


protected

  def load_and_authorize_parent_object
    parent_id = params['generic_file_id'] || params['intellectual_object_id']
    @parent_object = ActiveFedora::Base.find(parent_id)
    authorize! :update, @parent_object
  end

end
