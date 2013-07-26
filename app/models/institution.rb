class Institution < ActiveFedora::Base
  has_metadata 'adminMetadata', type: Datastream::InstitutionMetadata

  has_many :description_objects, property: :is_part_of

  delegate :name, to: 'adminMetadata', unique: true

  validates :name, presence: true
  validate :name_is_unique

  private

  def name_is_unique
    errors.add(:name, "must be unique") unless !Institution.all.map(&:name).include?(self.name)
  end
end