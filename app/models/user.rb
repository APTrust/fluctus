require 'bcrypt'

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
  devise :database_authenticatable, :recoverable, :rememberable, :trackable,
  :timeoutable, :validatable

  validates :email, :phone_number, :role_ids, presence: true
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

  def roles_for_transition
    if admin?
      'Admin'
    elsif institutional_admin?
      'Inst_Admin'
    elsif institutional_user?
      'Inst_User'
    end
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

  def institution_identifier
    institution = Institution.find(self.institution_pid)
    institution.identifier
  end

  # Blacklight uses #to_s on youruser class to get a user-displayable 
  # login/identifier for the account.
  #
  # Method modified from the Blacklight default.
  def to_s
    name || email
  end

  def as_json(options = nil)
    json_data = super
    json_data.delete('api_secret_key')
    json_data.delete('encrypted_api_secret_key')
    json_data
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

  def role_id
    if(admin?)
      Role.where(name: 'admin').first_or_create.id
    elsif(institutional_admin?)
      Role.where(name: 'institutional_admin').first_or_create.id
    elsif(institutional_user?)
      Role.where(name: 'institutional_user').first_or_create.id
    end
  end

  def main_group
    if(admin?)
      'Admin'
    elsif(institutional_admin?)
      'Institutional Admin'
    elsif(institutional_user?)
      'Institutional User'
    end
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

  attr_reader :api_secret_key

  def api_secret_key=(key)
    @api_secret_key = key
    self.encrypted_api_secret_key = if key.blank?
                                      nil
                                    else
                                      password_digest(key)
                                    end
  end

  # Generate a new API key for this user
  def generate_api_key(length = 20)
    self.api_secret_key = SecureRandom.hex(length)
  end

  # Verifies whether an API key (from sign in) matches the user's API key.
  def valid_api_key?(input_key)
    return false if encrypted_api_secret_key.blank?
    bcrypt  = ::BCrypt::Password.new(encrypted_api_secret_key)
    key = ::BCrypt::Engine.hash_secret("#{input_key}#{User.pepper}", bcrypt.salt)
    Devise.secure_compare(key, encrypted_api_secret_key)
  end

  # Sets a custom session time (in seconds) for the current user.
  def set_session_timeout(seconds)
    @session_timeout = seconds
  end

  # Returns the session duration, in seconds, for the current user.
  # For API use sessions, we set a long timeout
  # For all other users, we use the config setting Devise.timeout_in,
  # which is set in config/initializers/devise.rb.
  # For info on the timeout_in method, see:
  # https://github.com/plataformatec/devise/wiki/How-To:-Add-timeout_in-value-dynamically
  def timeout_in
    if !@session_timeout.nil? && @session_timeout > 0
      @session_timeout
    else
      Devise.timeout_in
    end
  end

  class NilInstitution
    def name
      'Deleted Institution'
    end

    def to_param
      'deleted'
    end

    def brief_name
      'Deleted Institution'
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
    errors.add(:institution_pid, 'is not a valid institution') unless Institution.exists?(institution_pid)
  end

end
