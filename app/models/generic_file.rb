class GenericFile < ActiveFedora::Base

  has_metadata "techMetadata", type: GenericFileMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  has_file_datastream "content", control_group: 'E'
  include Hydra::AccessControls::Permissions
  include Auditable   # premis events

  belongs_to :intellectual_object, property: :is_part_of

  has_attributes :uri, :size, :format, :created, :modified, :identifier, :md5, :sha256, datastream: 'techMetadata', multiple: false
  delegate :md5_attributes=, :md5, to: :techMetadata
  delegate :sha256_attributes=, :sha256, to: :techMetadata

  validates_presence_of :uri
  validates_presence_of :size
  validates_presence_of :created
  validates_presence_of :modified
  validates_presence_of :format
  #validates_presence_of :checksum
  validates_presence_of :identifier
  validate :has_right_number_of_checksums

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
      data.merge!(md5_attributes: serialize_md5) if options[:include].include?(:md5_attributes)
      data.merge!(sha256_attributes: serialize_sha256) if options[:include].include?(:sha256_attributes)
      data.merge!(premisEvents: serialize_events) if options[:include].include?(:premisEvents)
    end
    data
  end

  def serialize_md5
    md5.map do |cs|
      {
        algorithm: cs.algorithm.first,
        digest: cs.digest.first,
        datetime: Time.parse(cs.datetime.first).iso8601,
      }
    end
  end

  def serialize_sha256
    sha256.map do |cs|
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

  def has_right_number_of_checksums
    if(md5.count == 0 && sha256.count == 0)
      errors.add(:md5, "either this or the sha256 needs a value")
      errors.add(:sha256, "either this or the md5 needs a value")
    elsif(md5.count > 1 || sha256.count > 1)
      if(md5.count > 1)
        errors.add(:md5, "there can only be one value in this field")
      else
        errors.add(:sha256, "there can only be one value in this field")
      end
    elsif(md5.count > 1 && sha256.count > 1)
      errors.add(:md5, "there can only be one value in this field")
      errors.add(:sha256, "there can only be one value in this field")
    end
  end


end
