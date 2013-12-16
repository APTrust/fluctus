class GenericFile < ActiveFedora::Base

  has_metadata "descMetadata", type: GenericFileMetadata
  has_metadata "premisEvents", type: PremisEventsMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::ModelMixins::RightsMetadata

  belongs_to :intellectual_object, property: :is_part_of

  delegate_to 'descMetadata', [:uri, :size, :format, :created, :modified], unique: true
  delegate_to 'descMetadata', [:checksum]

  validates_presence_of :uri
  validates_presence_of :size
  validates_presence_of :created
  validates_presence_of :modified
  validates_presence_of :format
  validates_presence_of :checksum

  def set_permissions
    io = self.intellectual_object
    self.discover_groups = io.discover_groups
    self.read_groups = io.read_groups
    self.edit_groups = io.edit_groups
  end

  :set_permissions

end