# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController
  include Aptrust::GatedSearch
  self.solr_search_params_logic += [:add_access_controls_to_solr_params]
  self.solr_search_params_logic += [:only_active_objects]
end
