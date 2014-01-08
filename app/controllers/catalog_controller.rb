# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController
  include Aptrust::GatedSearch
end
