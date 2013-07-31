class Institution < ActiveFedora::Base
  include Hydra::ModelMixins::RightsMetadata
  has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata

  has_metadata 'adminMetadata', type: Datastream::InstitutionMetadata

  has_many :description_objects, property: :is_part_of

  delegate :name, to: 'adminMetadata', unique: true

  validates :name, presence: true
  validate :name_is_unique
  validate :check_for_users, on: :delete

  private

  # To determine uniqueness we must check all name values in all Institution objects.  This
  # becomes problematic on update because the name exists already and the validation fails.  Therefore
  # we must remove self from the array before testing for uniqueness.
  def name_is_unique
    errors.add(:name, "must be unique") unless !Institution.all.reject{|r| r == self}.map(&:name).include?(self.name)
  end

  def check_for_users
    count = User.where(institution_name: self.name).count
    errors.add(:name, "cannot be deleted because #{count} users are associated with this insitution.") unless count == 0
  end
end