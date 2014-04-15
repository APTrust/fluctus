class InstitutionsController < ApplicationController
  inherit_resources
  before_filter :authenticate_user!
  before_filter :set_institution

  include Blacklight::SolrHelper

  def destroy
    name = @institution.name
    destroy!(notice: "#{name} was successfully destroyed.")
  end

  private
    def set_institution
      @institution = params[:institution_identifier].nil? ? current_user.institution : Institution.where(desc_metadata__institution_identifier_tesim: params[:institution_identifier]).first
      authorize! params[:action].to_sym, @institution
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def build_resource_params
      params[:action] == 'new' ? [] : [params.require(:institution).permit(:name, :institution_identifier)]
    end

end
