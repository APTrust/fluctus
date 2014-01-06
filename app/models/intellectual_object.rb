class IntellectualObject < ActiveFedora::Base

  has_metadata "descMetadata", type: IntellectualObjectMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::AccessControls::Permissions
  include Aptrust::SolrHelper

  belongs_to :institution, property: :is_part_of
  has_many :generic_files, property: :is_part_of

  has_attributes :title, :rights, datastream: 'descMetadata', multiple: false
  has_attributes :description, :identifier, datastream: 'descMetadata', multiple: true

  validates_presence_of :title
  validates_presence_of :institution
  validates_presence_of :identifier
  validates_presence_of :rights
  validates_inclusion_of :rights, in: %w(public institution private), message: "#{:rights} is not a valid rights", if: :rights

  before_save :set_permissions
  before_destroy :check_for_associations

  def terms_for_editing
    [:title, :description, :rights]
  end

  def to_solr(solr_doc=Hash.new)
    super(solr_doc).tap do |doc|
      Solrizer.set_field(doc, 'institution_name', institution.name, :stored_sortable)
      Solrizer.insert_field(doc, 'format', generic_files.map(&:format), :facetable)
    end
  end

  private
    def set_permissions
      inst_pid = clean_for_solr(self.institution.pid)
      inst_admin_group = "Admin_At_#{inst_pid}"
      inst_user_group = "User_At_#{inst_pid}"
      case rights
        when 'public'
          self.read_groups = %w(institutional_admin institutional_user)
          self.edit_groups = [inst_admin_group]
        when 'institution'
          self.read_groups = [inst_user_group]
          self.edit_groups = [inst_admin_group]
        when 'private'
          self.discover_groups = [inst_user_group]
          self.edit_groups = [inst_admin_group]
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
