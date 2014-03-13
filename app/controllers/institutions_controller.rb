class InstitutionsController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_action :set_institution, only: [:show, :edit, :update, :destroy]

  include Blacklight::SolrHelper
  
  # DELETE /institutions/1
  # DELETE /institutions/1.json
  def get_institution
    unless params[:identifier].nil?
      unless Institution.where(desc_metadata__identifier_tesim: params[:identifier]).empty?
        @institution = Institution.where(desc_metadata__identifier_tesim: params[:identifier]).first
      end
    end


    if params[:identifier].nil?
      @institution
    else
      @institution = Institution.where(desc_metadata__identifier_tesim: params[:identifier]).first
    end
  end

  def destroy
    @institution = get_institution
    name = @institution.name
    destroy!(notice: "#{name} was successfully destroyed.")
  end

  def show
    @institution = get_institution
  end

  def edit
    @institution = get_institution
  end

  def update
    @institution = get_institution
    update!
  end

  private
    # If an id is passed through params, use it.  Otherwise default to show a current user's institution.
    def set_institution
      @institution = params[:id].nil? ? current_user.institution : Institution.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def build_resource_params
      params[:action] == 'new' ? [] : [params.require(:institution).permit(:name, :identifier)]
    end

end
