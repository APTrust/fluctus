# Generated via
#  `rails generate active_fedora::model IntellectualObject`
class IntellectualObject < ActiveFedora::Base
    # Creating a #descMetadata method that returns the datastream.
  #
  has_metadata "descMetadata", type: IntellectualObjectMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::ModelMixins::RightsMetadata

  belongs_to :institution, property: :is_part_of
  has_many :generic_files, property: :is_part_of

  # NOTE this should return a single string for convienence but some experimentation will need to be done.
  # arrays can be set in the datastream itself but it always returns first title as a string here.
  delegate_to 'descMetadata', [:title, :rights], unique: true

  # TODO get this to work at the top of the object
  delegate_to 'descMetadata', [:description, :identifier]

  validates_presence_of :title
  validates_presence_of :institution
  validates_presence_of :identifier
  validates_presence_of :rights
  validates_inclusion_of :rights, in: %w(public institution private), message: "#{:rights} is not a valid rights"

  def set_permissions
    inst_pid = self.institution
    inst_admin_group = "#{inst_pid}admin"
    inst_user_group = "#{inst_pid}user"
    rights = self.rights
    if rights.include?('public')
      self.set_discover_groups(['admin', 'institutional_admin', 'institutional_user'], [])
      self.set_read_groups(['admin', 'institutional_admin', 'institutional_user'], [])
      self.set_edit_groups(['admin', inst_admin_group], [])
    elsif rights.include?('institution')
      self.set_discover_groups(['admin', inst_admin_group, inst_user_group], [])
      self.set_read_groups(['admin', inst_admin_group, inst_user_group], [])
      self.set_edit_groups(['admin', inst_admin_group], [])
    elsif rights.include?('private')
      self.set_discover_groups(['admin', inst_admin_group, inst_user_group], [])
      self.set_read_groups(['admin', inst_admin_group], [])
      self.set_edit_groups(['admin', inst_admin_group], [])
    else
      self.set_discover_groups(['admin'], [])
      self.set_read_groups(['admin'], [])
      self.set_edit_groups(['admin'], [])
    end
  end


  before_destroy :check_for_associations

  def to_solr(solr_doc=Hash.new)
    super(solr_doc)
    solr_doc[ActiveFedora::SolrService.solr_name('institution_name', :stored_searchable)] = self.institution.name
    solr_doc[ActiveFedora::SolrService.solr_name('institution_name', :facetable)] = self.institution.name
    solr_doc[ActiveFedora::SolrService.solr_name('title', :stored_searchable)] = self.title
    solr_doc[ActiveFedora::SolrService.solr_name('rights', :facetable)] = self.rights
    solr_doc[ActiveFedora::SolrService.solr_name('original_pid', :stored_searchable)] = self.identifier
    return solr_doc
  end

  def check_for_associations
    # Check for related GenericFiles

    if self.generic_files.count != 0
      errors[:base] << "Cannot delete #{self.pid} because Generic Files are associated with it"
    end

    return false if !errors[:base].empty?
  end

end
