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
    end
  end

  def institutional_admin_permissions
    if current_user.is? :institutional_admin
      can :add_user, Institution, id: current_user.institution_pid
      can :add_user, Role, name: 'institutional_user'
      can [:read, :update, :destroy], User, institution_pid: current_user.institution_pid
      can [:create], User
      can [:read, :update], Institution, pid: current_user.institution_pid
      cannot :create, Institution
    end
  end
  
  def institutional_user_permissions
    if current_user.is? :institutional_user
      can :manage, User, id: current_user.id
      can :read, Institution, pid: current_user.institution_pid
      cannot :create, Institution
    end
  end
end
