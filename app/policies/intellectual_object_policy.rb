class IntellectualObjectPolicy < ApplicationPolicy

	# authorize through institution
	def index?
		user.admin? ||  (user.institution_pid == record.pid)
	end
	
	# authorize through institution
	def create?
		user.admin? || 
		(user.institutional_admin? && user.institution_pid == record.pid)
	end

	# authorize through institution
	def new?
		create?
	end

	def show?
		if user.admin? || record.access == 'consortia'
			true
		elsif record.access == 'institution'
			user.institution_pid == record.institution_id
		elsif record.access == 'restricted'
			user.institutional_admin? && user.institution_pid == record.institution_id
		end
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