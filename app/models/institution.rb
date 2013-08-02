class Institution < ActiveFedora::Base
  include Hydra::ModelMixins::RightsMetadata

  has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata

  has_metadata 'adminMetadata', type: Datastream::InstitutionMetadata

  has_many :description_objects, property: :is_part_of

  delegate :name, to: 'adminMetadata', unique: true

  validates :name, presence: true
  validate :name_is_unique

  before_destroy :check_for_associations

  private

  # To determine uniqueness we must check all name values in all Institution objects.  This
  # becomes problematic on update because the name exists already and the validation fails.  Therefore
  # we must remove self from the array before testing for uniqueness.
  def name_is_unique
    errors.add(:name, "must be unique") unless !Institution.all.reject{|r| r == self}.map(&:name).include?(self.name)
  end

  def check_for_associations
    # Check for related Users
    #
    # This is a relationship with an ActiveRecord object, so we must ask the ActiveRecord object about the relationship.
    if User.where(institution_name: self.name).count != 0
      errors[:base] << "Cannot delete #{self.name} because some Users are associated with this Insitution"
    end

    # Check for related DescriptionObjects
    #
    # This is a relationship with another ActiveFedora object, so the traditional .where method won't work.
    # We must rely upon the ActiveFedora object reporting the relationship count information.
    if self.description_objects.count != 0
      errors[:base] << "Cannot delete #{self.name} because Description Objects are associated with it"
    end

    return false if !errors[:base].empty?
  end
end