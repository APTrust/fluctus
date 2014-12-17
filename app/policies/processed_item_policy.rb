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

  def search?
    user.admin? || (user.institution.identifier == record.institution)
  end

	def show?
		record.nil? || user.admin? || (user.institution.identifier == record.institution)
	end

	def update?
		user.admin? ||
		(user.institutional_admin? && (user.institution.identifier == record.institution))
	end

	def edit?
		update?
	end

	def mark_as_reviewed?
    user.admin? || (user.institutional_admin? && (user.institution.identifier == record.institution))
  end

  def review_all?
    user.admin? || (user.institutional_admin? && (user.institution.identifier == record.institution))
  end

	def destroy?
		false
  end

  def set_restoration_status?
    user.admin? || (user.institutional_admin? && (user.institution.identifier == record.institution))
  end

  def items_for_delete?
    user.admin? || (user.institutional_admin? && (user.institution.identifier == record.institution))
  end

  def items_for_restore?
    user.admin? || (user.institutional_admin? && (user.institution.identifier == record.institution))
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
