class IntellectualObject < ActiveFedora::Base

  has_metadata "descMetadata", type: IntellectualObjectMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
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

  # This governs which fields show up on the editor. This is part of the expected interface for hydra-editor
  def terms_for_editing
    [:title, :description, :access]
  end

  def to_solr(solr_doc=Hash.new)
    super(solr_doc).tap do |doc|
      Solrizer.set_field(doc, 'institution_name', institution.name, :stored_sortable)
      aggregate = IoAggregation.where(identifier: self.id).first
      unless aggregate.nil?
        Solrizer.set_field(doc, 'file_format', aggregate.formats_for_solr, :facetable)
        Solrizer.set_field(doc, 'total_file_size', aggregate.file_size, :symbol)
        Solrizer.set_field(doc, 'active_count', aggregate.file_count, :symbol)
      end
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
    query ||= []
    query << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{pid}")
    query << ActiveFedora::SolrService.construct_query_for_rel(object_state_ssi: 'A')
    solr_result = ActiveFedora::SolrService.query(query, :rows => row, :start => start)
    files = []
    solr_result.each do |file|
      file = [file]
      result = ActiveFedora::SolrService.reify_solr_results(file, {:load_from_solr=>true})
      initial_result = result.first
      real_result = initial_result.reify
      files.push(real_result)
    end
    files
  end

  def aggregations_from_solr
    row = 100000
    start = 0
    query ||= []
    query << ActiveFedora::SolrService.construct_query_for_rel(is_part_of: "info:fedora/#{self.id}")
    query << ActiveFedora::SolrService.construct_query_for_rel(object_state_ssi: 'A')
    solr_result = ActiveFedora::SolrService.query(query, :rows => row, :start => start)
    total_files = solr_result.count
    format_map = {}
    size = 0
    solr_result.each do |file|
      current_format = file['tech_metadata__file_format_ssi']
      if format_map.include?(current_format)
        count = format_map[current_format]
        count = count + 1
        format_map[current_format] = count
      else
        format_map[current_format] = 1
      end
      current_size = file['tech_metadata__size_lsi'].to_i
      size = size + current_size
    end
    aggregations = {num_files: total_files, formats: format_map, size: size}
    aggregations
  end

  def soft_delete(attributes)
    self.state = 'D'
    self.add_event(attributes)
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

  private
  def identifier_is_unique
    return if self.identifier.nil?
    count = 0;
    objects = IntellectualObject.where(desc_metadata__identifier_ssim: self.identifier)
    count +=1 if objects.count == 1 && objects.first.id != self.id
    count = objects.count if objects.count > 1
    #puts "Count: #{count}, Identifier: #{self.identifier}"
    if(count > 0)
      errors.add(:identifier, "has already been taken")
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
      pieces = self.identifier.split("/")
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
