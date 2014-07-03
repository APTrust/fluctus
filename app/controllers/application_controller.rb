class ApplicationController < ActionController::Base

  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller
  include ApiAuth
   
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, :if => :api_request?

   # If a User is denied access for an action, return them back to the last page they could view.
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html { redirect_to root_url, alert: exception.message }
      format.json { render :json => { :status => "error", :message => exception.message }, :status => :forbidden }
    end 
  end

  def after_sign_in_path_for(resource)
    session[:purge_datetime] = Time.now
    session[:show_reviewed] = false
    root_path()
  end

end
