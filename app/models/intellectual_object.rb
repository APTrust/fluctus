# Generated via
#  `rails generate active_fedora::model IntellectualObject`
class IntellectualObject < ActiveFedora::Base

  # Creating a #descMetadata method that returns the datastream. 
  #
  has_metadata "descMetadata", type: IntellectualObjectMetadata
  has_metadata "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

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

  def check_permissions
    if :rights.include? 'public'
      self.discover_groups = %w(admin, institutional_admin, institutional_user)
      self.read_groups = %w(admin, institutional_admin, institutional_user)
      self.edit_groups = %w(admin, institutional_admin)
    elsif :rights.include? 'institution'
      self.discover_groups = %w(admin, institutional_admin, institutional_user)
      self.read_groups = %w(admin, institutional_admin, institutional_user)
      self.edit_groups = %w(admin, institutional_admin)
    elsif :rights.include? 'private'
      self.discover_groups = %w(admin, institutional_admin, institutional_user)
      self.read_groups = %w(admin, institutional_admin)
      self.edit_groups = %w(admin, institutional_admin)
    else
      self.discover_groups = %w[admin]
      self.read_groups = %w[admin]
      self.edit_groups = %w[admin]
    end

  end

end
