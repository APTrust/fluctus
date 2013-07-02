class CompressedBag < ActiveFedora::Base
  has_metadata 'descMetadata', type: Datastream::BagMetadata

  belongs_to :bag, property: :is_derivation_of

end