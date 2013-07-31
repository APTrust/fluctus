class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors. 
  include Hydra::User

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  
  # Connects this user object to Role-management behaviors. 
  include Hydra::RoleManagement::UserRoles

  # Include default devise modules. Others available are:
  # :database_authenticatable,
  # :recoverable, :rememberable, :trackable, :validatable,
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :registerable, :omniauth_providers => [:google_oauth2]

  validates :email, :phone_number, presence: true
  validates :email, uniqueness: true
  validates :institution_name, presence: true
  validates_inclusion_of :institution_name, in: -> (institution) {Institution.all.map(&:name)}

  # Custom format validations.  See app/validators
  validates :name, person_name_format: true
  validates :email, email: true
  validates :phone_number, phone_format: true

  # Blacklight uses #to_s on youruser class to get a user-displayable 
  # login/identifier for the account. 
  #
  # Method modified from the Blacklight default.
  def to_s
    name.nil? ? email : name
  end

  # Roles are managed through the hydra-role-management gem.
  def is?(role)
    self.roles.pluck(:name).include?(role.to_s)
  end

  # Since an Institution is an ActiveFedora Object, these two objects cannot be related as normal (i.e. belogns_to)
  # They will be connected through the Institution.name which should be unique.
  def institution
    return Institution.where(name: self.institution_name).first
  end

  # Guest users are disabled in this application.  The default Blacklight installation includes the gem devise-guests
  # which is not bundled with this app.  hydra-roles-management gem requires a guest boolean, so we must provide it here.
  def guest?
    false
  end

  # This method comes from the oauth2 documentation on Github.  The only alteration is that when a user is
  # not found, a new User with no attributes is created.  This is necessary to disable the creation of
  # unauthorized users.
  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:email => data["email"]).first

    unless user
      # Return a new user rather than create one since Users should not be able to create their own accounts.
      user = User.new
    end
    user
  end
end
