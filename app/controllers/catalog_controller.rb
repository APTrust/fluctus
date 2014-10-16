# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController
  include Aptrust::GatedSearch
  apply_catalog_search_params
end
