class IntellectualObject < ActiveFedora::Base

  has_metadata 'descMetadata', type: IntellectualObjectMetadata
  has_metadata 'rightsMetadata', :type => Hydra::Datastream::RightsMetadata
  include Hydra::AccessControls::Permissions
  include Aptrust::SolrHelper
  include Auditable   # premis events

  belongs_to :institution, property: :is_part_of
  has_many :generic_files, property: :is_part_of
  accepts_nested_attributes_for :generic_files

  has_attributes :title, :access, :description, :identifier, :bag_name, datastream: 'descMetadata', multiple: false
  has_attributes :alt_identifier, datastream: 'descMetadata', multiple: true

  validates_presence_of :title
  validates_presence_of :institution
  validates_presence_of :identifier
  validates_presence_of :access
  validates_inclusion_of :access, in: %w(consortia institution restricted), message: "#{:access} is not a valid access", if: :access
  validate :identifier_is_unique

  before_save :set_permissions
  before_save :set_bag_name
  before_save :active_files
  before_destroy :check_for_associations

  def to_param
   identifier
  end

  def institution_identifier
    inst = self.identifier.split('/')
    inst[0]
  end

  # This governs which fields show up on the editor. This is part of the expected interface for hydra-editor
  def terms_for_editing
    [:title, :description, :access]
  end

  def to_solr(solr_doc=Hash.new)
    super(solr_doc).tap do |doc|
      Solrizer.set_field(doc, 'institution_name', institution.name, :stored_sortable)
    end
  end

  def self.get_from_solr(pid)
    query = "id\:#{RSolr.escape(pid)}"
    solr_result = ActiveFedora::SolrService.query(query)
    result = ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
    initial_result = result.first
    real_result = initial_result.reify
    real_result
  end

  def self.files_from_solr(pid, options={})
    row = options[:rows] || 10
    start = options[:start] || 0
    files = GenericFile.where(object_state_ssi: 'A', is_part_of_ssim: "info:fedora/#{pid}").order('latest_fixity_dti asc').offset(start).limit(row)
    files
  end

  def bytes_by_format
    resp = ActiveFedora::SolrService.instance.conn.get 'select', :params => {
      'q' => 'tech_metadata__size_lsi:[* TO *]',
      'fq' =>[ActiveFedora::SolrService.construct_query_for_rel(:has_model => GenericFile.to_class_uri),
           "_query_:\"{!raw f=is_part_of_ssim}info:fedora/#{self.id}\""],
      'stats' => true,
      'fl' => '',
      'stats.field' =>'tech_metadata__size_lsi',
      'stats.facet' => 'tech_metadata__file_format_ssi'
                                                               }
    stats = resp['stats']['stats_fields']['tech_metadata__size_lsi']
    if stats
      cross_tab = stats['facets']['tech_metadata__file_format_ssi'].each_with_object({}) { |(k,v), obj|
        obj[k] = v['sum']
      }
      cross_tab['all'] = stats['sum']
      cross_tab
    else
      {'all' => 0}
    end
  end

  def soft_delete(attributes)
    self.state = 'D'
    self.add_event(attributes)
    save!
    Thread.new() do
      background_deletion(attributes)
      ActiveRecord::Base.connection.close
    end
  end

  def in_dpn?
    object_in_dpn = false
    dpn = Fluctus::Application::FLUCTUS_ACTIONS['dpn']
    record = Fluctus::Application::FLUCTUS_STAGES['record']
    success = Fluctus::Application::FLUCTUS_STATUSES['success']
    dpn_items = ProcessedItem.where(object_identifier: self.identifier, action: dpn)
    dpn_items.each do |item|
      if item.stage == record && item.status == success
        object_in_dpn = true
        break
      end
    end
    object_in_dpn
  end

  def background_deletion(attributes)
    generic_files.each do |gf|
      gf.soft_delete(attributes)
    end
    save!
  end

  def gf_count
    count = 0
    self.generic_files.each { |gf| count = count+1 unless gf.state == 'D' }
    count
  end

  def gf_size
    size = 0
    self.generic_files.each { |gf| size = size+gf.size unless gf.state == 'D' }
    size
  end

  def active_files
    files = []
    self.generic_files.each { |gf| files.push(gf) unless gf.state == 'D'}
    files
  end

  # This is for serializing JSON in the API.
  def serializable_hash(options={})
    data = {
        id: id,
        title: title,
        description: description,
        access: access,
        bag_name: bag_name,
        identifier: identifier,
        state: state,
    }
    data.merge!(alt_identifier: serialize_alt_identifiers)
    if options.has_key?(:include)
      options[:include].each do |opt|
        if opt.is_a?(Hash) && opt.has_key?(:active_files)
          data.merge!(active_files: serialize_active_files(opt[:active_files]))
        end
      end
      data.merge!(premisEvents: serialize_events) if options[:include].include?(:premisEvents)
      if options[:include].include?(:etag)
        item = ProcessedItem.last_ingested_version(self.identifier)
        data.merge!(etag: item.etag) unless item.nil?
      end
    end
    data
  end

  def serialize_active_files(options={})
    self.active_files.map do |file|
      file.serializable_hash(options)
    end
  end

  def serialize_events
    self.premisEvents.events.map do |event|
      event.serializable_hash
    end
  end

  def serialize_alt_identifiers
    data = []
    alt_identifier.each do |ident|
      data.push(ident)
    end
    data
  end

  private
  def identifier_is_unique
    return if self.identifier.nil?
    count = 0;
    objects = IntellectualObject.where(desc_metadata__identifier_ssim: self.identifier)
    unless objects.count == 0
      count +=1 if objects.count == 1 && objects.first.id != self.id
      count = objects.count if objects.count > 1
    end
    if(count > 0)
      errors.add(:identifier, 'has already been taken')
    end
  end

  def set_permissions
    inst_pid = clean_for_solr(self.institution.pid)
    inst_admin_group = "Admin_At_#{inst_pid}"
    inst_user_group = "User_At_#{inst_pid}"
    case access
      when 'consortia'
        self.read_groups = %w(institutional_admin institutional_user)
        self.edit_groups = [inst_admin_group]
      when 'institution'
        self.read_groups = [inst_user_group]
        self.edit_groups = [inst_admin_group]
      when 'restricted'
        self.discover_groups = [inst_user_group]
        self.edit_groups = [inst_admin_group]
    end
  end

  def set_bag_name
    return if self.identifier.nil?
    if self.bag_name.nil? || self.bag_name == ''
      pieces = self.identifier.split('/')
      i = 1
      while i < pieces.count do
        (i == 1) ? name = pieces[1] : name = "#{name}/#{pieces[i]}"
        i = i+1
      end
      self.bag_name = name
    end
  end

  def check_for_associations
    # Check for related GenericFiles
    unless generic_file_ids.empty?
      errors[:base] << "Cannot delete #{self.pid} because Generic Files are associated with it"
    end
    errors[:base].empty?
  end

end
