class Institution < ActiveFedora::Base
  include Hydra::ModelMixins::RightsMetadata
  has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata

  has_metadata 'adminMetadata', type: Datastream::InstitutionMetadata

  has_many :description_objects, property: :is_part_of

  delegate :name, to: 'adminMetadata', unique: true
  delegate :contacts, to: 'adminMetadata'
end