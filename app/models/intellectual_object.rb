# Generated via
#  `rails generate active_fedora::model IntellectualObject`
class IntellectualObject < ActiveFedora::Base

  # Creating a #descMetadata method that returns the datastream. 
  #
  has_metadata "descMetadata", type: IntellectualObjectMetadata

  belongs_to :institution, property: :is_part_of

  delegate_to 'descMetadata', [:title], unique: true

  # TODO get this to work at the top of the object
  # delegate_to 'descMetadata', [:identifier, :description]

  validates :title, presence: true
  validates :institution, presence: true

end
