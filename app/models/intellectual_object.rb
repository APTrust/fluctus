class IntellectualObject < ActiveFedora::Base

  has_metadata "descMetadata", type: IntellectualObjectMetadata

  belongs_to :institution, property: :is_part_of
  has_many :generic_files, property: :is_part_of

  has_attributes :title, :rights, datastream: 'descMetadata', multiple: false
  has_attributes :description, :identifier, datastream: 'descMetadata', multiple: true

  validates_presence_of :title
  validates_presence_of :institution
  validates_presence_of :identifier
  validates_presence_of :rights
  validates_inclusion_of :rights, in: %w(public institution private), message: "#{:rights} is not a valid rights"

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
