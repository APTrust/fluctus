class Institution < ActiveFedora::Base
  has_metadata 'adminMetadata', type: Datastream::InstitutionMetadata

  has_many :description_objects, property: :is_part_of

  delegate :name, to: 'adminMetadata', unique: true
  delegate :contacts, to: 'adminMetadata'

end