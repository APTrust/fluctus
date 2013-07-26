class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors. 
  include Hydra::User
 
  # Connects this user object to Role-management behaviors. 
  include Hydra::RoleManagement::UserRoles

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User

  # Include default devise modules. Others available are:
  # :database_authenticatable,
  # :recoverable, :rememberable, :trackable, :validatable,
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :registerable, :omniauth_providers => [:google_oauth2]

  validates :email, :phone_number, presence: true
  validates :email, uniqueness: true

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    name.nil? ? email : name
  end

  def is?(role)
    self.roles.include?(role.to_s)
  end

  # Guest users are disabled in this application.  The default Blacklight installation includes the gem devise-guests
  # which is not bundled with this app.  hydra-roles-management gem requires a guest boolean, so we must provide it here.
  def guest?
    false
  end

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:email => data["email"]).first

    unless user
      user = User.create(name: data["name"], email: data["email"])
    end
    user
  end
end
