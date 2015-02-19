require 'spec_helper'

describe UserPolicy do
  subject (:user_policy) { UserPolicy.new(user, other_user) }
  let(:institution) { FactoryGirl.create(:institution) }

  context "for an admin user" do
    let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
    describe "when the user is any other user" do
      let(:other_user) { FactoryGirl.create(:user) }
      it do
        should allow(:create)
        should allow(:new)
        should allow(:show)
        should allow(:update)
        should allow(:edit)
        should allow(:generate_api_key)
        should allow(:edit_password)
        should allow(:update_password)
        should allow(:destroy)
        should allow(:admin_password_reset)
      end
    end
    describe "when the user is him/herself" do
      let(:other_user) { user }
      it do
        should allow(:generate_api_key)
        should allow(:admin_password_reset)
      end
    end
  end

  context "for an institutional admin user" do
    let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: institution.pid ) }
    describe "when the user is any other user " do
      describe "in my institution" do
        let(:other_user) { FactoryGirl.create(:user, institution_pid: institution.pid) }
        it do
          should allow(:create)
          should allow(:new)
          should allow(:show)
          should allow(:update)
          should allow(:edit)
          should_not allow(:generate_api_key)
          should_not allow(:edit_password)
          should_not allow(:update_password)
          should allow(:destroy)
          should_not allow(:admin_password_reset)
        end
      end

      describe "not in my institution" do
        let(:other_user) { FactoryGirl.create(:user) }        
        it do
          should_not allow(:show)
          should_not allow(:update)
          should_not allow(:edit)
          should_not allow(:generate_api_key)
          should_not allow(:edit_password)
          should_not allow(:update_password)
          should_not allow(:destroy)
          should_not allow(:admin_password_reset)
        end
      end
    end
    describe "when the user is him/herself" do
      let(:other_user) { user }
      it do
        should allow(:generate_api_key)
        should_not allow(:admin_password_reset)
      end
    end
  end

  context "for an institutional user" do
    let(:user) { FactoryGirl.create(:user, :institutional_user, institution_pid: institution.pid) }
    describe "when the user is" do
      describe "in my institution" do
        let(:other_user) { FactoryGirl.create(:user, institution_pid: institution.pid) }
        it do
          should_not allow(:create)
          should_not allow(:new)
          should_not allow(:show)
          should_not allow(:update)
          should_not allow(:edit)
          should_not allow(:generate_api_key)
          should_not allow(:edit_password)
          should_not allow(:update_password)
          should_not allow(:destroy)
          should_not allow(:admin_password_reset)
        end 
      end

      describe "not in my institution" do
        let(:other_user) { FactoryGirl.create(:user) }
        it do
          should_not allow(:show)
          should_not allow(:update)
          should_not allow(:edit)
          should_not allow(:generate_api_key)
          should_not allow(:edit_password)
          should_not allow(:update_password)
          should_not allow(:destroy)
          should_not allow(:admin_password_reset)
        end 
      end

      describe "him/herself" do
        let(:other_user) { user }
        it do
          should allow(:show)
          should allow(:update)
          should allow(:edit)
          should allow(:generate_api_key)
          should allow(:edit_password)
          should allow(:update_password)
          should_not allow(:destroy)
          should_not allow(:admin_password_reset)
        end
      end
    end
  end
  
  context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user, :institutional_user, institution_pid: institution.pid) }
    it do
      should_not allow(:create)
      should_not allow(:new)
      should_not allow(:show)
      should_not allow(:update)
      should_not allow(:edit)
      should_not allow(:generate_api_key)
      should_not allow(:destroy)
      should_not allow(:admin_password_reset)
    end
  end 
end