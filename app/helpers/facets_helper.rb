module FacetsHelper
  # This module exists because Hydra does some weird overrides of the facet behaviors in hydra-core 6.4
  include Blacklight::FacetsHelperBehavior
end
