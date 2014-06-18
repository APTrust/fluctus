class GenericFile < ActiveFedora::Base

  has_metadata "techMetadata", type: GenericFileMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  has_file_datastream "content", control_group: 'E'
  include Hydra::AccessControls::Permissions
  include Auditable   # premis events

  belongs_to :intellectual_object, property: :is_part_of

  has_attributes :uri, :size, :format, :created, :modified, :identifier, datastream: 'techMetadata', multiple: false
  delegate :checksum_attributes=, :checksum, to: :techMetadata

  validates_presence_of :uri
  validates_presence_of :size
  validates_presence_of :created
  validates_presence_of :modified
  validates_presence_of :format
  validates_presence_of :checksum
  validates_presence_of :identifier

  before_save :copy_permissions_from_intellectual_object
  after_save :update_parent_index

  delegate :institution, to: :intellectual_object

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

  # This is for serializing JSON in the API
  def serializable_hash(options={})
    {
      uri: uri,
      size: size,
      created: created,
      modified: modified,
      format: format,
      checksum_attributes: serialize_checksums,
      identifier: identifier,
      premisEvents: serialize_events,
    }
  end

  def serialize_checksums
    checksum.map do |cs|
      {
        algorithm: cs.algorithm.first,
        digest: cs.digest.first,
        datetime: cs.datetime.first,
      }
    end
  end

  def serialize_events
    premisEvents.events.map do |event|
      {
        identifier: event.identifier.first,
        type: event.type.first,
        date_time: event.date_time.first,
        detail: event.detail.first,
        outcome: event.outcome.first,
        outcome_detail: event.outcome_detail.first,
        object: event.object.first,
        agent: event.agent.first,
        outcome_information: event.outcome_information.first,
      }
    end
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
