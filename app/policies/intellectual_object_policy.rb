class IntellectualObjectPolicy < ApplicationPolicy

	def index?
		if user.admin?
			true
		elsif record.access == 'consortia'
			user.institutional_admin? || user.institutional_user?
		# if restricted or institutional access
		else
			user.institution_pid == record.institution_id
		end
	end

	def file_summary?
		if user.admin?
			true
		elsif record.intellectual_object.access == 'consortia'
			user.institutional_admin? || user.institutional_user?
		# if restricted or institutional access
		else
			user.institution_pid == record.intellectual_object.institution_id
		end
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
		if user.admin?
			true
		elsif record.access == 'consortia'
			user.institutional_admin? || user.institutional_user?
		elsif record.access == 'institution'
			user.institution_pid == record.institution_id
		# if restricted access
		else
			user.institutional_admin? && user.institution_pid == record.institution_id
		end
	end

	def update?
		user.admin?
	end

	def edit?
		false
	end

	def destroy?
		soft_delete?
	end

	def soft_delete?
		user.admin? ||
		(user.institutional_admin? && user.institution_pid == record.institution_id)
  end

  def restore?
    user.admin? || (user.institutional_admin? && user.institution_pid == record.institution_id)
	end

	def dpn?
		user.admin? || (user.institutional_admin? && user.institution_pid == record.institution_id)
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
