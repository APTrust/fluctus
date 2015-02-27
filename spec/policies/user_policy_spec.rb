require 'spec_helper'

describe UserPolicy do
  subject (:user_policy) { UserPolicy.new(user, other_user) }
  let(:institution) { FactoryGirl.create(:institution) }

  context "for an admin user" do
    let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
    describe "when the user is any other user" do
      let(:other_user) { FactoryGirl.create(:user) }
      it do
        should allow_to(:create)
        should allow_to(:new)
        should allow_to(:show)
        should allow_to(:update)
        should allow_to(:edit)
        should allow_to(:generate_api_key)
        should allow_to(:edit_password)
        should allow_to(:update_password)
        should allow_to(:destroy)
        should allow_to(:admin_password_reset)
      end
    end
    describe "when the user is him/herself" do
      let(:other_user) { user }
      it do
        should allow_to(:generate_api_key)
        should allow_to(:admin_password_reset)
      end
    end
  end

  context "for an institutional admin user" do
    let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: institution.pid ) }
    describe "when the user is any other user " do
      describe "in my institution" do
        let(:other_user) { FactoryGirl.create(:user, institution_pid: institution.pid) }
        it do
          should allow_to(:create)
          should allow_to(:new)
          should allow_to(:show)
          should allow_to(:update)
          should allow_to(:edit)
          should_not allow_to(:generate_api_key)
          should_not allow_to(:edit_password)
          should_not allow_to(:update_password)
          should allow_to(:destroy)
          should_not allow_to(:admin_password_reset)
        end
      end

      describe "not in my institution" do
        let(:other_user) { FactoryGirl.create(:user) }        
        it do
          should_not allow_to(:show)
          should_not allow_to(:update)
          should_not allow_to(:edit)
          should_not allow_to(:generate_api_key)
          should_not allow_to(:edit_password)
          should_not allow_to(:update_password)
          should_not allow_to(:destroy)
          should_not allow_to(:admin_password_reset)
        end
      end
    end
    describe "when the user is him/herself" do
      let(:other_user) { user }
      it do
        should allow_to(:generate_api_key)
        should_not allow_to(:admin_password_reset)
      end
    end
  end

  context "for an institutional user" do
    let(:user) { FactoryGirl.create(:user, :institutional_user, institution_pid: institution.pid) }
    describe "when the user is" do
      describe "in my institution" do
        let(:other_user) { FactoryGirl.create(:user, institution_pid: institution.pid) }
        it do
          should_not allow_to(:create)
          should_not allow_to(:new)
          should_not allow_to(:show)
          should_not allow_to(:update)
          should_not allow_to(:edit)
          should_not allow_to(:generate_api_key)
          should_not allow_to(:edit_password)
          should_not allow_to(:update_password)
          should_not allow_to(:destroy)
          should_not allow_to(:admin_password_reset)
        end 
      end

      describe "not in my institution" do
        let(:other_user) { FactoryGirl.create(:user) }
        it do
          should_not allow_to(:show)
          should_not allow_to(:update)
          should_not allow_to(:edit)
          should_not allow_to(:generate_api_key)
          should_not allow_to(:edit_password)
          should_not allow_to(:update_password)
          should_not allow_to(:destroy)
          should_not allow_to(:admin_password_reset)
        end 
      end

      describe "him/herself" do
        let(:other_user) { user }
        it do
          should allow_to(:show)
          should allow_to(:update)
          should allow_to(:edit)
          should allow_to(:generate_api_key)
          should allow_to(:edit_password)
          should allow_to(:update_password)
          should_not allow_to(:destroy)
          should_not allow_to(:admin_password_reset)
        end
      end
    end
  end
  
  context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user, :institutional_user, institution_pid: institution.pid) }
    it do
      should_not allow_to(:create)
      should_not allow_to(:new)
      should_not allow_to(:show)
      should_not allow_to(:update)
      should_not allow_to(:edit)
      should_not allow_to(:generate_api_key)
      should_not allow_to(:destroy)
      should_not allow_to(:admin_password_reset)
    end
  end 
end