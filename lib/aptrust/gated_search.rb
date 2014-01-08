module Aptrust::GatedSearch
  extend ActiveSupport::Concern
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior

  included do
    # These before_filters apply the hydra access controls
    before_filter :enforce_show_permissions, only: :show
    # This applies appropriate access controls to all solr queries
    self.solr_search_params_logic += [:add_access_controls_to_solr_params]
    include Aptrust::BlacklightConfiguration
  end

  # Override hydra-access-controls so that admins aren't gated. 
  def apply_gated_discovery(solr_parameters, user_parameters)
    return if current_user && current_user.admin?
    super
  end

end
