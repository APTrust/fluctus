class ProcessedItemPolicy < ApplicationPolicy
	
	def create?
		user.admin?
	end

	def new?
		create?
	end

	def index?
		user.admin? ||  (user.institution.identifier == record.institution)
	end

	def show?
		user.admin? || (user.institution.identifier == record.institution)
	end

	def update?
		user.admin? 
	end

	def edit?
		update?
	end	

	def mark_as_reviewed?
		user.admin? || 
		(user.institutional_admin? && (user.institution.identifier == record.institution))
	end

	def destroy?
		user.admin?
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
        scope.where(institution: user.institution.identifier)
      end
    end
  end
end