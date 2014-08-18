require 'spec_helper'

describe UserPolicy do

  let(:institution) { FactoryGirl.create(:institution) }
	let(:admin) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
  let(:inst_admin) { FactoryGirl.create(:user, :institutional_admin, institution_pid: institution.pid ) }
  let(:user) { FactoryGirl.create(:user, institution_pid: institution.pid) }
  let(:other_user) { FactoryGirl.create(:user) }

  context "for an admin user" do
    
    subject (:user_policy) { UserPolicy.new(admin, other_user) }
    it { should permit(:create) }
    it { should permit(:new) }
    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:edit) }
    it { should permit(:generate_api_key)}
    it { should permit(:edit_password) }
    it { should permit(:update_password) }
    it { should permit(:destroy) }
  end

  context "for an institutional admin user" do
    
    describe "when the user is" do
      describe "in my institution" do
        subject (:user_policy) { UserPolicy.new(inst_admin, user) }
        it { should permit(:create) }
        it { should permit(:new) }
        it { should permit(:show) }
        it { should permit(:update) }
        it { should permit(:edit) }
        it { should_not permit(:generate_api_key) }
        it { should_not permit(:edit_password) }
        it { should_not permit(:update_password) }
        it { should permit(:destroy) } 
      end

      describe "not in my institution" do
        subject (:user_policy) { UserPolicy.new(inst_admin, other_user) }
        
        it { should_not permit(:show) }
        it { should_not permit(:update) }
        it { should_not permit(:edit) }
        it { should_not permit(:generate_api_key) }
        it { should_not permit(:edit_password) }
        it { should_not permit(:update_password) }
        it { should_not permit(:destroy) }  
      end
    end
  end

  context "for an institutional user" do

    describe "when the user is" do
      describe "in my institution" do
        subject (:user_policy) { UserPolicy.new(user, inst_admin) }
        it { should_not permit(:create) }
        it { should_not permit(:new) }
        it { should_not permit(:show) }
        it { should_not permit(:update) }    
        it { should_not permit(:edit) }
        it { should_not permit(:generate_api_key) }
        it { should_not permit(:edit_password) }
        it { should_not permit(:update_password) }
        it { should_not permit(:destroy) }
      end

      describe "not in my institution" do
        subject (:user_policy) { UserPolicy.new(user, other_user) }
        it { should_not permit(:show) }
        it { should_not permit(:update) }
        it { should_not permit(:edit) }
        it { should_not permit(:generate_api_key) }
        it { should_not permit(:edit_password) }
        it { should_not permit(:update_password) }
        it { should_not permit(:destroy) }  
      end

      describe "herself" do
        subject (:user_policy) { UserPolicy.new(user, user) }
        it { should permit(:show) }
        it { should permit(:update) }
        it { should permit(:edit) }
        it { should permit(:generate_api_key) }
        it { should permit(:edit_password) }
        it { should permit(:update_password) }
        it { should_not permit(:destroy) } 
      end
    end
  end
  
  context "for an authenticated user without a user group" do
    subject (:user_policy) { UserPolicy.new(other_user, user) }
    it { should_not permit(:create) }
    it { should_not permit(:new) }
    it { should_not permit(:show) }
    it { should_not permit(:update) }    
    it { should_not permit(:edit) }
    it { should_not permit(:generate_api_key) }
    it { should_not permit(:destroy) }
  end 
end