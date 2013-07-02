class DescriptionObject < ActiveFedora::Base
  has_metadata 'descMetadata', type: Datastream::DescriptionObjectMetadata

  belongs_to :institution, property: :is_part_of

  delegate :title, to: 'descMetadata'
  delegate :dpn_status, to: 'descMetadata'

end