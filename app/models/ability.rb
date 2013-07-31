class Ability
  # CanCan::Ability is included in Hydra::Ability so no need to include it here
  # include CanCan::Ability
  include Hydra::Ability
  include Hydra::PolicyAwareAbility

  # customizing permissions as directed:
  # https://github.com/projecthydra/hydra-head/blob/master/hydra-access-controls/lib/hydra/ability.rb
  self.ability_logic +=[:admin_permissions, :institutional_admin_permissions, :institutional_user_permissions]

  def admin_permissions
    if current_user.is? :admin
      can :manage, :all 
      can :manage_user_roles, User
      can :manage_user_institution, User
      can :assign_admin_user, User
    end
  end

  def institutional_admin_permissions
    if current_user.is? :institutional_admin
      can [:create, :read, :update, :destroy, :manage_user_roles], User, institution_name: current_user.institution_name
      cannot [:manage_user_institution, :assign_admin_user], User
    end
  end
  
  def institutional_user_permissions
    if current_user.is? :institutional_user
      can :manage, User, id: current_user.id
      cannot [:manage_user_roles, :manage_user_institution], User
      can :read, Institution, name: current_user.institution_name
      cannot :create, Institution
    end
  end
end
