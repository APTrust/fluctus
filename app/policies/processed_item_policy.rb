class ProcessedItemPolicy < ApplicationPolicy
	
	# no create button for admin or institutional_admin
	def create?
		user.admin?
	end

	def new?
		create?
	end

	def index?
		user.admin? ||  user.institutional_admin? || user.institutional_user?
	end

	# institutional_user doen not read ability
	def show?
		user.admin? || (user.institution.identifier == record.institution)
	end

	# can edit but shown error message
	def update?
		user.admin? || 
		(user.institutional_admin? && (user.institution.identifier == record.institution))
	end

	def edit?
		update?
	end	

	def mark_as_reviewed?
		user.admin? || 
		(user.institutional_admin? && (user.institution.identifier == record.institution))
	end

	# institutional_admin cannot delete intellectual_object
	def destroy?
		false
	end
end