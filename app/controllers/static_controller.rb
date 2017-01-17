class StaticController < ApplicationController
  inherit_resources
  before_filter :authenticate_user!
  after_action :verify_authorized

  def index
    authorize current_user, :static_page?
    message = "As of January 17, 2017, you'll find APTrust's production repository at https://repo.aptrust.org, and our " +
              'demo repository at https://demo.aptrust.org. These servers are now running APTrust 2.0. For more information ' +
              "about what's new in 2.0, see https://sites.google.com/a/aptrust.org/member-wiki/recent-changes. If you have " +
              'questions, please contact us at help@aptrust.org.'
    respond_to do |format|
      format.json {
        render :json => { status: 'Error - Page Moved', message: message }, :status => 301
      }
      format.html { }
    end
  end
end