# Generated via
#  `rails generate active_fedora::model IntellectualObject`
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
  validates_inclusion_of :rights, in: %w(public institution private), message: "#{:rights} is not a valid rights"

  def set_permissions
    inst_pid = clean_for_solr(self.institution.pid)
    inst_admin_group = "Admin_At_#{inst_pid}"
    inst_user_group = "User_At_#{inst_pid}"
    rights = self.rights
    if rights.include?('public')
      self.discover_groups = %w(admin institutional_admin institutional_user)
      self.read_groups = %w(admin institutional_admin institutional_user)
      self.edit_groups = ['admin', inst_admin_group]
    elsif rights.include?('institution')
      self.discover_groups = ['admin', inst_admin_group, inst_user_group]
      self.read_groups = ['admin', inst_admin_group, inst_user_group]
      self.edit_groups = ['admin', inst_admin_group]
    elsif rights.include?('private')
      self.discover_groups = ['admin', inst_admin_group, inst_user_group]
      self.read_groups = ['admin', inst_admin_group]
      self.edit_groups = ['admin', inst_admin_group]
    else
      self.discover_groups = %w(admin)
      self.read_groups = %w(admin)
      self.edit_groups = %w(admin)
    end
  end

  before_save :set_permissions

  before_destroy :check_for_associations

  def terms_for_editing
    [:title, :description]
  end

  def to_solr(solr_doc=Hash.new)
    super(solr_doc).tap do |doc|
      Solrizer.set_field(doc, 'institution_name', institution.name, :stored_sortable)
      Solrizer.insert_field(doc, 'format', generic_files.map(&:format), :facetable)
    end
  end

  private

    def check_for_associations
      # Check for related GenericFiles

      if self.generic_files.count != 0
        errors[:base] << "Cannot delete #{self.pid} because Generic Files are associated with it"
      end

      errors[:base].empty?
    end

end
