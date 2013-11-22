# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Aptrust::SolrHelper
  include Aptrust::BlacklightConfiguration

  # TODO Change this back before merging to develop.
  ## These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  #
  ## This applies appropriate access controls to all solr queries
  #CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]

  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.solr_search_params_logic += [:exclude_unwanted_models]

  # Added by APTrust.  Filter results based on User's insitutional affilation.  Superusers
  # are not constrained in the same way, however.
  CatalogController.solr_search_params_logic += [:filter_on_institution]

end
