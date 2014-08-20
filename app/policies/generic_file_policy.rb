class GenericFilePolicy < ApplicationPolicy
	
	def create?
		user.admin? || 
		(user.institutional_admin? && (user.institution_pid == record.intellectual_object.institution_id)) 
	end

	def new?
		create?
	end

	def index?
		user.admin? ||  
		(user.institutional_admin? && (user.institution_pid == record.intellectual_object.institution_id))
	end

	# only admin user has detailed view ability
	def show?
		user.admin?
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