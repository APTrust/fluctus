class IntellectualObjectPolicy < ApplicationPolicy

	def index?
		user.admin? || record.access == 'consortia' || 
			user.institution_pid == record.institution_id
	end
	
	# for generic_file object
	def create_through_intellectual_object?
		user.admin?  || 
			(user.institutional_admin? && user.institution_pid == record.institution_id)
	end

	# for adding premis events
	def add_event?
		user.admin? || 
			(user.institutional_admin? && user.institution_pid == record.institution_id)
	end

	def show?
		if user.admin? || record.access == 'consortia'
			true
		elsif record.access == 'institution'
			user.institution_pid == record.institution_id
		# if restricted access or no access field in testing environment
		else
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

	def soft_delete?
		user.admin? || 
		(user.institutional_admin? && user.institution_pid == record.institution_id)
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