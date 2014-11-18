class GenericFile < ActiveFedora::Base

  has_metadata "techMetadata", type: GenericFileMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  has_file_datastream "content", control_group: 'E'
  include Hydra::AccessControls::Permissions
  include Auditable   # premis events

  belongs_to :intellectual_object, property: :is_part_of

  has_attributes :uri, :size, :file_format, :created, :modified, :identifier, datastream: 'techMetadata', multiple: false
  delegate :checksum_attributes=, :checksum, to: :techMetadata

  validates_presence_of :uri
  validates_presence_of :size
  validates_presence_of :created
  validates_presence_of :modified
  validates_presence_of :file_format
  validates_presence_of :identifier
  validate :has_right_number_of_checksums
  validate :identifier_is_unique

  before_save :copy_permissions_from_intellectual_object
  after_save :update_parent_index

  delegate :institution, to: :intellectual_object

  def to_solr(solr_doc = {})
    super
    Solrizer.insert_field(solr_doc, 'institution_uri', intellectual_object.institution.internal_uri, :symbol)
    Solrizer.insert_field(solr_doc, 'gf_institution_name', intellectual_object.institution.name, :symbol)
    Solrizer.insert_field(solr_doc, 'gf_parent', intellectual_object.identifier, :symbol)
    Solrizer.insert_field(solr_doc, 'latest_fixity', self.find_latest_fixity_check, :searchable, :sortable)
  end

  def self.file_from_solr(pid)
    query = "id\:#{RSolr.escape(pid)}"
    solr_result = ActiveFedora::SolrService.query(query)
    result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
    initial_result = result.first
    real_result = initial_result.reify
    real_result
  end

  def find_latest_fixity_check
    fixity = ''
    premisEvents.events.each do |event|
      if event.type.first == 'fixity_check'
        if fixity == '' || fixity == nil? || DateTime.parse(fixity.to_s) < DateTime.parse(event.date_time.to_s)
          fixity = DateTime.parse(event.date_time.to_s)
        end
      end
    end
    fixity
  end

  def self.find_files_in_need_of_fixity(date, options={})
    row = options[:rows] || 10
    start = options[:start] || 0
    #query ||= []
    #query << ActiveFedora::SolrService.construct_query_for_rel(has_model: GenericFile.to_class_uri, object_state_ssi: 'A', latest_fixity_dti: "[* TO #{date}]")
    #solr_result = ActiveFedora::SolrService.query(query, :rows => row, :start => start)
    #files = []
    #solr_result.each do |file|
    #  file = [file]
    #  result = ActiveFedora::SolrService.reify_solr_results(file, {:load_from_solr=>true})
    #  initial_result = result.first
    #  real_result = initial_result.reify
    #  files.push(real_result)
    #end
    files = GenericFile.where("object_state_ssi:A AND latest_fixity_dti:[* TO #{date}]").order('latest_fixity_dti asc').limit(row)
    files
  end

  def filter_query(query, args={})
    raw = args.delete(:raw)
    args = args.merge(:fq=>query, :qt=>'standard')
    result = ActiveFedora::SolrService.instance.conn.get('select', :params=>args)
    return result if raw
    result['response'['docs']]
  end

  def display
    identifier
  end

  def content_uri= uri
    content.dsLocation = uri
  end

  def soft_delete(attributes)
    user_email = attributes[:outcome_detail]
    ProcessedItem.create_delete_request(self.intellectual_object.identifier,
                                        self.identifier,
                                        user_email)
    self.state = 'D'
    self.add_event(attributes)
    save!
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
      size: size.to_i,
      created: Time.parse(created).iso8601,
      modified: Time.parse(modified).iso8601,
      file_format: file_format,
      identifier: identifier,
      state: state,
    }
    if options.has_key?(:include)
      data.merge!(checksum: serialize_checksums) if options[:include].include?(:checksum)
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

  # Returns the checksum with the specified digest, or nil.
  # No need to specify algorithm, since we're using md5 and sha256,
  # and their digests have different lengths.
  def find_checksum_by_digest(digest)
    checksum.select { |cs| digest.strip == cs.digest.first.to_s.strip }.first
  end

  # Returns true if the GenericFile has a checksum with the specified digest.
  def has_checksum?(digest)
    find_checksum_by_digest(digest).nil? == false
  end

  private

  def update_parent_index
    #TODO in order to improve performance, you can put this work in a background job

    # Force the generic_files to be reloaded
    # These could have been deleted, but they're still in solr

    # TURNED OFF BY A.D. 7/7/2014 BECAUSE SYSTEM IS UNUSABLE IN PRODUCTION WITH REINDEXING ON!
    # intellectual_object.generic_files(true)
    # intellectual_object.update_index
  end

  def copy_permissions_from_intellectual_object
    self.permissions = intellectual_object.permissions if intellectual_object
  end

  def has_right_number_of_checksums
    if(checksum.count == 0)
      errors.add(:checksum, "can't be blank")
    else
      algorithms = Array.new
      checksum.each do |cs|
        if (algorithms.include? cs)
          errors.add(:checksum, "can't have multiple checksums with same algorithm")
        else
          algorithms.push(cs)
        end
      end
    end
  end

  def identifier_is_unique
    return if self.identifier.nil?
    count = 0;
    files = GenericFile.where(tech_metadata__identifier_ssim: self.identifier)
    count +=1 if files.count == 1 && files.first.id != self.id
    count = files.count if files.count > 1
    if(count > 0)
      errors.add(:identifier, "has already been taken")
    end
  end

end
