class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors. 
  include Hydra::User

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  include Aptrust::SolrHelper
  
  # Connects this user object to Role-management behaviors. 
  include Hydra::RoleManagement::UserRoles

  # Include default devise modules. Others available are:
  # :database_authenticatable,
  # :recoverable, :rememberable, :trackable, :validatable,
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :timeoutable, :validatable

  validates :email, :phone_number, presence: true
  validates :email, uniqueness: true
  validates :institution_pid, presence: true
  validate :institution_pid_points_at_institution

  # Custom format validations.  See app/validators
  validates :name, person_name_format: true, if: ->{ name.present? }
  validates :email, email: true

  # Handle and normalize phone numbers
  phony_normalize :phone_number, :default_country_code => 'US'

  validates :phone_number, :phony_plausible => true

  # This method assigns permission groups
  def groups
    super + institution_groups
  end

  def institution_groups
    if institutional_admin?
      ["Admin_At_#{institution_group_suffix}"]
    elsif institutional_user?
      ["User_At_#{institution_group_suffix}"]
    else
      []
    end
  end

  # Blacklight uses #to_s on youruser class to get a user-displayable 
  # login/identifier for the account. 
  #
  # Method modified from the Blacklight default.
  def to_s
    name || email
  end

  # Roles are managed through the hydra-role-management gem.
  def is?(role)
    self.roles.pluck(:name).include?(role.to_s)
  end

  def admin?
    is? 'admin'
  end

  def institutional_admin?
    is? 'institutional_admin'
  end

  def institutional_user?
    is? 'institutional_user'
  end


  # Since an Institution is an ActiveFedora Object, these two objects cannot be related as normal (i.e. belongs_to)
  # They will be connected through the User.institution_pid.
  def institution
    @institution ||= Institution.find(self.institution_pid)
  rescue ActiveFedora::ObjectNotFoundError => e
    logger.warn "#{self.institution_pid} is set as the institution for #{self}, but it doesn't exist"
    @institution = NilInstitution.new
  end

  def institution_group_suffix
    clean_for_solr(institution_pid)
  end

  # Guest users are disabled in this application.  The default Blacklight installation includes the gem devise-guests
  # which is not bundled with this app.  hydra-role-management gem requires a guest boolean, so we must provide it here.
  # This will be fixed in hydra-role-management 0.1.1
  def guest?
    false
  end

  class NilInstitution
    def name
      "Deleted Institution"
    end

    def to_param
      'deleted'
    end

    def brief_name
      "Deleted Institution"
    end

    def users
      []
    end

    def intellectual_objects
      []
    end

    def bytes_by_format
      {}
    end
  end

  private

  def institution_pid_points_at_institution
    errors.add(:institution_pid, "is not a valid institution") unless Institution.exists?(institution_pid)
  end

end
