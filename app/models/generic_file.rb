class GenericFile < ActiveFedora::Base

  has_metadata "descMetadata", type: GenericFileMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  has_file_datastream "content", control_group: 'E'
  include Hydra::AccessControls::Permissions
  include Auditable   # premis events

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
  after_save :update_parent_index

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

  private 

  def update_parent_index
    #TODO in order to improve performance, you can put this work in a background job
    intellectual_object.generic_files.reset
    intellectual_object.update_index
  end

  def copy_permissions_from_intellectual_object
    self.permissions = intellectual_object.permissions
  end


end
