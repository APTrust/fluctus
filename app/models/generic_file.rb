class GenericFile < ActiveFedora::Base

  has_metadata "descMetadata", type: GenericFileMetadata
  has_metadata "premisEvents", type: PremisEventsMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::AccessControls::Permissions

  belongs_to :intellectual_object, property: :is_part_of

  has_attributes :uri, :size, :format, :created, :modified, datastream: 'descMetadata', multiple: false
  delegate :checksum_attributes=, :checksum, to: :descMetadata

  validates_presence_of :uri
  validates_presence_of :size
  validates_presence_of :created
  validates_presence_of :modified
  validates_presence_of :format
  validates_presence_of :checksum

  before_save :copy_permissions_from_intellectual_object

  def to_solr(solr_doc = {})
    super
    Solrizer.insert_field(solr_doc, 'institution_uri', intellectual_object.institution.internal_uri, :symbol)
  end

  private 
  def copy_permissions_from_intellectual_object
    io = self.intellectual_object
    self.discover_groups = io.discover_groups
    self.read_groups = io.read_groups
    self.edit_groups = io.edit_groups
  end


end
