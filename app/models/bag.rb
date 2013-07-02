class Bag < ActiveFedora::Base
  has_metadata 'descMetadata', type: Datastream::BagMetadata
  has_file_datastream 'bagContent'

  belongs_to :description_object, property: :is_part_of
  has_one :compressed_bag, property: :is_derivation_of  

end