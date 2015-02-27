require 'spec_helper'

describe InstitutionPolicy do 
	subject (:institution_policy) { InstitutionPolicy.new(user, institution) }
  let(:institution) { FactoryGirl.create(:institution) }
  let(:other_institution) { FactoryGirl.create(:institution) }      
  
  context "for an admin user" do
    let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
    describe "access any institution" do 
      it do
      	should allow_to(:create)
        should allow_to(:create_through_institution)
        should allow_to(:new)
        should allow_to(:show)
        should allow_to(:update)
        should allow_to(:edit)
        should allow_to(:add_user)
        should_not allow_to(:destroy)
      end
    end

    describe "access an intellectual object's institution" do
      let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
      let(:institution) { intellectual_object.institution}
      it { should allow_to(:add_user)}
    end
  end

  context "for an institutional admin user" do 	
  	describe "when the institution is" do
      describe "in my institution" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: institution.pid) } 
      	it do
          should allow_to(:show)
          should_not allow_to(:create)
          should allow_to(:create_through_institution)
          should_not allow_to(:new)
          should allow_to(:update)
          should allow_to(:edit)
          should allow_to(:add_user)
          should_not allow_to(:destroy)
        end
      end

      describe "not in my institution" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: other_institution.pid) } 
        it do
          should_not allow_to(:create)
          should_not allow_to(:create_through_institution)
          should_not allow_to(:new)
          should_not allow_to(:show)
          should_not allow_to(:update)
          should_not allow_to(:edit)
          should_not allow_to(:add_user)
          should_not allow_to(:destroy)
        end
      end
    end
  end

  context "for an institutional user" do
    describe "when the institution is" do
      describe "in my institution" do
    	 let(:user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: institution.pid) }
        it do
          should allow_to(:show)
          should_not allow_to(:create)
          should_not allow_to(:create_through_institution)
          should_not allow_to(:new)
          should_not allow_to(:update)
          should_not allow_to(:edit)
          should_not allow_to(:add_user)
          should_not allow_to(:destroy)
        end
      end

      describe "not in my institution" do
        let(:user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: other_institution.pid) }
        it do
          should_not allow_to(:create)
          should_not allow_to(:create_through_institution)
          should_not allow_to(:new)
          should_not allow_to(:show)
          should_not allow_to(:update)
          should_not allow_to(:edit)
          should_not allow_to(:add_user)
          should_not allow_to(:destroy)
        end
      end
    end
  end

	context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    it do
      should_not allow_to(:show)
      should_not allow_to(:create)
      should_not allow_to(:create_through_institution)
      should_not allow_to(:new)
      should_not allow_to(:update)
      should_not allow_to(:edit)
      should_not allow_to(:add_user)
      should_not allow_to(:destroy)
    end
  end
end