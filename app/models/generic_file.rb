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

  # This is for serializing JSON in the API.
  # Be sure all datetimes are formatted as ISO8601,
  # or some JSON parsers (like the golang parser)
  # will choke on them. The datetimes we pull back
  # from Fedora are strings that are not in ISO8601
  # format, so we have to parse & reformat them.
  def serializable_hash(options={})
    data = {
      id: id,
      uri: uri,
      size: size,
      created: Time.parse(created).iso8601,
      modified: Time.parse(modified).iso8601,
      format: format,
      identifier: identifier,
    }
    if options.has_key?(:include)
      data.merge!(checksum_attributes: serialize_checksums) if options[:include].include?(:checksum_attributes)
      data.merge!(premisEvents: serialize_events) if options[:include].include?(:premisEvents)
    end
    data
  end

  def serialize_checksums
    checksum.map do |cs|
      {
        algorithm: cs.algorithm.first,
        digest: cs.digest.first,
        datetime: Time.parse(cs.datetime.first).iso8601,
      }
    end
  end

  def serialize_events
    premisEvents.events.map do |event|
      event.serializable_hash
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
