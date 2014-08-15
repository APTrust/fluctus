class GenericFilePolicy < ApplicationPolicy
	
	# no create button for admin or institutional_admin
	def create?
		user.admin? || user.institutional_admin? 
	end

	def new?
		create?
	end

	def index?
		user.admin? ||  user.institutional_admin? || user.institutional_user?
	end

	# institutional_user do not have read ability
	def show?
		user.admin? || 
		(user.institutional_admin? && (user.institution_pid == record.intellectual_object.institution_id))
	end

	# can edit but shown error message
	def update?
		user.admin? 
	end

	def edit?
		update?
	end	

	# institutional_admin cannot delete intellectual_object
	def destroy?
		false
	end

	def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.admin?
        scope.all
      else
        scope.where(:intellectual_object => { :institution_id => user.institution_pid })
      end
    end
  end
end