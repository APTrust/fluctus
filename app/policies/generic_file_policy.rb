class GenericFilePolicy < ApplicationPolicy
	
	# authorize through intellectual_object
	def index?
		user.admin? ||  (user.institution_pid == record.institution_id)
	end

	# authorize through intellectual_object
	def create?
		user.admin? || 
		(user.institutional_admin? && user.institution_pid == record.institution_id)
	end

	def show?
		if user.admin? || record.intellectual_object.access == 'consortia'
			true
		elsif record.intellectual_object.access == 'institution'
			user.institution_pid == record.intellectual_object.institution_id
		elsif record.access == 'restricted'
			user.institutional_admin? && user.institution_pid == record.intellectual_object.institution_id
		end
	end

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