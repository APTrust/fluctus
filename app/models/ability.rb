class Ability
  include Hydra::Ability

  # customizing permissions as directed:
  # https://github.com/projecthydra/hydra-head/blob/master/hydra-access-controls/lib/hydra/ability.rb
  #self.ability_logic +=[:admin_permissions, :institutional_admin_permissions, :institutional_user_permissions]

  
  #def create_permissions
    # nop - override default behavior which allows any registered user to create
  #end

  #def admin_permissions
    #if current_user.is? :admin
      #can :manage, :all 
    #end
  #end

  #def institutional_admin_permissions
    #if current_user.is? :institutional_admin
      #can :add_user, Institution, id: current_user.institution_pid
      #can :add_user, Role, name: 'institutional_user'
      #can :add_user, Role, name: 'institutional_admin'
      # cannot delete user itself
      #can [:read, :update, :destroy], User, institution_pid: current_user.institution_pid
      #can [:create], User
      #can :generate_api_key, User, id: current_user.id
      #can [:edit_password, :update_password], User, id: current_user.id
      #can [:read, :update], Institution, pid: current_user.institution_pid
      #can :create, GenericFile, :intellectual_object => { :institution_id => current_user.institution_pid }
      #can [:create, :restore], IntellectualObject, institution_id: current_user.institution_pid
      #can [:read, :update], ProcessedItem, institution: current_user.institution.identifier
    #end
  #end

  #def institutional_user_permissions
    #if current_user.is? :institutional_user
      #can :manage, User, id: current_user.id
      #can :read, Institution, pid: current_user.institution_pid
      #can :read, ProcessedItem, institution: current_user.institution.identifier
    #end
  #end

  def force_to_utf8(value)
    case value
      when Hash
        value.each { |k, v| value[k] = force_to_utf8(v) }
      when Array
        value.each { |v| force_to_utf8(v) }
      when String
        value.force_encoding("utf-8")  if value.respond_to?(:force_encoding)
    end
    value
  end

end
