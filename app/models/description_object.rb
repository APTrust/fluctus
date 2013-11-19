# add a comment
class DescriptionObject < ActiveFedora::Base
  include Hydra::ModelMixins::RightsMetadata

  before_save :set_permissions

  has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata
  has_metadata 'descMetadata', type: Datastream::DescriptionObjectMetadata

  belongs_to :institution, property: :is_part_of
  has_many :bags, property: :is_part_of

  delegate_to 'descMetadata', [:title], unique: true

  validates :title, presence: true
  validates :institution, presence: true

  def to_solr(solr_doc=Hash.new)
    super(solr_doc)
    solr_doc[ActiveFedora::SolrService.solr_name('institution_name', :stored_searchable)] = self.institution.name
    solr_doc[ActiveFedora::SolrService.solr_name('institution_name', :facetable)] = self.institution.name
    solr_doc[ActiveFedora::SolrService.solr_name('original_pid', :stored_searchable)] = self.bags.first.parse_pid unless self.bags(true).empty?
    return solr_doc
  end

  private
  def set_permissions
    self.edit_groups = ['admin', 'institutional_admin']
    self.read_groups = ['institutional_guest']
  end
end