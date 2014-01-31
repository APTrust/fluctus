module Aptrust::GatedSearch
  extend ActiveSupport::Concern
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior

  included do
    # These before_filters apply the hydra access controls
    before_filter :enforce_show_permissions, only: :show

    include Aptrust::BlacklightConfiguration
  end

  module ClassMethods
    def apply_catalog_search_params
      # This applies appropriate access controls to all solr queries
      self.solr_search_params_logic += [:add_access_controls_to_solr_params]
      self.solr_search_params_logic += [:only_intellectual_objects]
      self.solr_search_params_logic += [:only_active_objects]
    end
  end

  protected

  # Override hydra-access-controls so that admins aren't gated. 
  def apply_gated_discovery(solr_parameters, user_parameters)
    return if current_user && current_user.admin?
    super
  end

  # Limits search results just to IntellectualObjects
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-submitted parameters
  def only_intellectual_objects(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << ActiveFedora::SolrService.construct_query_for_rel(has_model: IntellectualObject.to_class_uri)
  end

  # Limits search results just to ActiveObjects
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-submitted parameters
  def only_active_objects(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    case user_parameters[:show]
    when 'all'
      # no constraint
    when 'deleted'
      solr_parameters[:fq] << "_query_:\"{!raw f=object_state_ssi}D\""
    else
      # constrain to active
      solr_parameters[:fq] << "_query_:\"{!raw f=object_state_ssi}A\""
    end
  end

end
