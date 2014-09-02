class GenericFilePolicy < ApplicationPolicy
	
	def index?
		user.admin? ||  (user.institution_pid == record.intellectual_object.institution_id)
	end

	def create?
		user.admin? 
	end

	# for adding premis events
	def add_event?
		(user.admin? && record) || 
		(user.institutional_admin? && user.institution_pid == record.intellectual_object.institution_id)
	end

	def show?
		puts "what is access #{record.intellectual_object.access}"
		if user.admin? || record.intellectual_object.access == 'consortia'
			true
		elsif record.intellectual_object.access == 'institution'
			user.institution_pid == record.intellectual_object.institution_id
		# if restricted access or no access field in testing environment
		else
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

	def soft_delete?
		user.admin? || 
		(user.institutional_admin? && user.institution_pid == record.intellectual_object.institution_id)
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