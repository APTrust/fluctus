class GenericFile < ActiveFedora::Base

  has_metadata "techMetadata", type: GenericFileMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  has_file_datastream "content", control_group: 'E'
  include Hydra::AccessControls::Permissions
  include Auditable   # premis events

  belongs_to :intellectual_object, property: :is_part_of

  has_attributes :uri, :size, :format, :created, :modified, :generic_file_identifier, :intellectual_object_identifier, :institution_identifier, datastream: 'techMetadata', multiple: false
  delegate :checksum_attributes=, :checksum, to: :techMetadata

  validates_presence_of :uri
  validates_presence_of :size
  validates_presence_of :created
  validates_presence_of :modified
  validates_presence_of :format
  validates_presence_of :checksum
  validates_presence_of :generic_file_identifier

  before_save :copy_permissions_from_intellectual_object
  before_save :set_identifiers
  after_save :update_parent_index

  delegate :institution, to: :intellectual_object

  def to_param
    generic_file_identifier
  end

  def to_solr(solr_doc = {})
    super
    Solrizer.insert_field(solr_doc, 'institution_uri', intellectual_object.institution.internal_uri, :symbol)
  end

  def content_uri= uri
    content.dsLocation = uri
  end

  def soft_delete
    self.state = 'D'
    premisEvents.events.build(type: 'delete')
    save!
    OrderUp.push(DeleteGenericFileJob.new(id))
  end

  def set_identifiers
    self.institution_identifier = self.intellectual_object.institution_identifier
    self.intellectual_object_identifier = self.intellectual_object.intellectual_object_identifier
  end

  private 

  def update_parent_index
    #TODO in order to improve performance, you can put this work in a background job

    # Force the generic_files to be reloaded
    # These could have been deleted, but they're still in solr
    intellectual_object.generic_files(true)
    intellectual_object.update_index
  end

  def copy_permissions_from_intellectual_object
    self.permissions = intellectual_object.permissions if intellectual_object
  end


end
