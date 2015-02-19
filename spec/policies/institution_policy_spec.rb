require 'spec_helper'

describe InstitutionPolicy do 
	subject (:institution_policy) { InstitutionPolicy.new(user, institution) }
  let(:institution) { FactoryGirl.create(:institution) }
  let(:other_institution) { FactoryGirl.create(:institution) }      
  
  context "for an admin user" do
    let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
    describe "access any institution" do 
      it do
      	should allow(:create)
        should allow(:create_through_institution)
        should allow(:new)
        should allow(:show)
        should allow(:update)
        should allow(:edit)
        should allow(:add_user)
        should_not allow(:destroy)
      end
    end

    describe "access an intellectual object's institution" do
      let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
      let(:institution) { intellectual_object.institution}
      it { should allow(:add_user)}
    end
  end

  context "for an institutional admin user" do 	
  	describe "when the institution is" do
      describe "in my institution" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: institution.pid) } 
      	it do
          should allow(:show)
          should_not allow(:create)
          should allow(:create_through_institution)
          should_not allow(:new)
          should allow(:update)
          should allow(:edit)
          should allow(:add_user)
          should_not allow(:destroy)
        end
      end

      describe "not in my institution" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: other_institution.pid) } 
        it do
          should_not allow(:create)
          should_not allow(:create_through_institution)
          should_not allow(:new)
          should_not allow(:show)
          should_not allow(:update)
          should_not allow(:edit)
          should_not allow(:add_user)
          should_not allow(:destroy)
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
          should allow(:show)
          should_not allow(:create)
          should_not allow(:create_through_institution)
          should_not allow(:new)
          should_not allow(:update)
          should_not allow(:edit)
          should_not allow(:add_user)
          should_not allow(:destroy)
        end
      end

      describe "not in my institution" do
        let(:user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: other_institution.pid) }
        it do
          should_not allow(:create)
          should_not allow(:create_through_institution)
          should_not allow(:new)
          should_not allow(:show)
          should_not allow(:update)
          should_not allow(:edit)
          should_not allow(:add_user)
          should_not allow(:destroy)
        end
      end
    end
  end

	context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    it do
      should_not allow(:show)
      should_not allow(:create)
      should_not allow(:create_through_institution)
      should_not allow(:new)
      should_not allow(:update)
      should_not allow(:edit)
      should_not allow(:add_user)
      should_not allow(:destroy)
    end
  end
end