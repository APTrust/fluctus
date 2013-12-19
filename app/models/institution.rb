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

  private

  # To determine uniqueness we must check all name values in all Institution objects.  This
  # becomes problematic on update because the name exists already and the validation fails.  Therefore
  # we must remove self from the array before testing for uniqueness.
  def name_is_unique
    errors.add(:name, "has already been taken") unless !Institution.all.reject{|r| r == self}.map(&:name).include?(self.name)
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
