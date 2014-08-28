class IntellectualObjectPolicy < ApplicationPolicy

	def index?
		user.admin? ||  (user.institution_pid == record.institution_id)
	end
	
	def show?
		user.admin? ||  (user.institution_pid == record.institution_id)
	end

	def update?
		user.admin? 
	end

	def edit?
		update?
	end	

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
        scope.where(institution_id: user.institution_pid)
      end
    end
  end
end