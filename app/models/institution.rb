class Institution < ActiveFedora::Base
  include Hydra::AccessControls::Permissions

  # NOTE with rdf datastreams must query like so ins = Institution.where(desc_metadata__name_tesim: "APTrust")
  has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata
  has_metadata 'descMetadata', type: InstitutionMetadata

  has_many :intellectual_objects, property: :is_part_of

  has_attributes :name, :brief_name, datastream: 'descMetadata', multiple: false

  validates :name, presence: true
  validate :name_is_unique

  before_destroy :check_for_associations

  # Return the users that belong to this institution.  Sorted by name for display purposes primarily.
  def users
    User.where(institution_pid: self.pid).to_a.sort_by(&:name)
  end

  def bytes_by_format
    resp = ActiveFedora::SolrService.instance.conn.get 'select', :params => {
      'q' => 'desc_metadata__size_isi:[* TO *]',
      'fq' =>[ActiveFedora::SolrService.construct_query_for_rel(:has_model => GenericFile.to_class_uri),
              "_query_:\"{!raw f=institution_uri_ssim}#{internal_uri}\""],
      'stats' => true,
      'fl' => '',
      'stats.field' =>'desc_metadata__size_isi',
      'stats.facet' => 'desc_metadata__format_ssi'
    }
    stats = resp['stats']['stats_fields']['desc_metadata__size_isi']
    if stats
      cross_tab = stats['facets']['desc_metadata__format_ssi'].each_with_object({}) { |(k,v), obj|
        obj[k] = v['sum']
      }
      cross_tab['Total content upload'] = stats['sum']
      cross_tab
    else
      {'Total content upload' => 0}
    end

  end
  private

  # To determine uniqueness we must check all name values in all Institution objects.  This
  # becomes problematic on update because the name exists already and the validation fails.  Therefore
  # we must remove self from the array before testing for uniqueness.
  def name_is_unique
    errors.add(:name, "has already been taken") if Institution.where(desc_metadata__name_tesim: self.name).reject{|r| r == self}.any?
  end

  def check_for_associations
    # Check for related Users
    #
    # This is a relationship with an ActiveRecord object, so we must ask the ActiveRecord object about the relationship.
    if User.where(institution_pid: self.pid).count != 0
      errors[:base] << "Cannot delete #{self.name} because some Users are associated with this Insitution"
    end

    # Check for related DescriptionObjects
    #
    # This is a relationship with another ActiveFedora object, so the traditional .where method won't work.
    # We must rely upon the ActiveFedora object reporting the relationship count information.
    if self.intellectual_objects.count != 0
      errors[:base] << "Cannot delete #{self.name} because Intellectual Objects are associated with it"
    end

    errors[:base].empty?
  end

end
