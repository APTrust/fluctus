class CompressedBag < ActiveFedora::Base
  include Hydra::ModelMixins::RightsMetadata
  has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata
  
  has_metadata 'descMetadata', type: Datastream::BagMetadata

  belongs_to :bag, property: :is_derivation_of

end