class GenericFile < ActiveFedora::Base

  has_metadata "descMetadata", type: GenericFileMetadata
  has_metadata "premisEvents", type: PremisEventsMetadata

  belongs_to :intellectual_object, property: :is_part_of

  has_attributes :uri, :size, :format, :created, :modified, datastream: 'descMetadata', multiple: false
  has_attributes :checksum, datastream: 'descMetadata', multiple: true

  validates_presence_of :uri
  validates_presence_of :size
  validates_presence_of :created
  validates_presence_of :modified
  validates_presence_of :format
  validates_presence_of :checksum

end
