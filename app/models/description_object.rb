class DescriptionObject < ActiveFedora::Base

  include Hydra::ModelMixins::RightsMetadata
  before_save :set_permissions

  has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata
  has_metadata 'descMetadata', type: Datastream::DescriptionObjectMetadata

  belongs_to :institution, property: :is_part_of

  delegate :title, to: 'descMetadata', unique: true
  delegate :dpn_status, to: 'descMetadata', unique: true

  validates :title, :dpn_status, presence: true

  private
  def set_permissions
    self.edit_groups = ['admin', 'institutional_admin']
    self.read_groups = ['institutional_guest']
  end
end