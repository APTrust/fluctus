class GenericFile < ActiveFedora::Base

  has_metadata "descMetadata", type: GenericFileMetadata
  has_metadata "premisEvents", type: PremisEventsMetadata

  belongs_to :intellectual_object, property: :is_part_of

end