class InstitutionsController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_institution, only: [:show, :edit, :update, :destroy]

  include Blacklight::SolrHelper
  
  # DELETE /institutions/1
  # DELETE /institutions/1.json
  def destroy
    name = @institution.name
    destroy!(notice: "#{name} was successfully destroyed.")
  end
  
  private
    # If an id is passed through params, use it.  Otherwise default to show a current user's institution.
    def set_institution
      @institution = params[:id].nil? ? current_user.institution : Institution.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def build_resource_params
      params[:action] == 'new' ? [] : [params.require(:institution).permit(:name)]
    end

end
