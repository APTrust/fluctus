require 'spec_helper'

describe IntellectualObjectPolicy do 

  subject (:intellectual_object_policy) { IntellectualObjectPolicy.new(user, intellectual_object) }
  let(:institution) { FactoryGirl.create(:institution) }
    
  context "for an admin user" do
  	let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
  	let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }

  	it { should permit(:create) }
    it { should permit(:new) }
    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:edit) }
    it { should_not permit(:destroy) }
  end

  context "for an institutional admin user" do
  	let(:user) { FactoryGirl.create(:user, :institutional_admin, 
  		                               institution_pid: institution.pid) }
    describe "when the object is" do
      describe "in my institution" do
        let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: institution) }
        it { should permit(:create) }
        it { should permit(:new) }
        it { should permit(:show) }
        it { should_not permit(:update) }    
        it { should_not permit(:edit) }
        it { should_not permit(:destroy) }
      end

      describe "not in my institution" do
        let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
        
        it { should_not permit(:show) }
        it { should_not permit(:update) }    
        it { should_not permit(:edit) }
        it { should_not permit(:destroy) }
      end
    end
  end

  context "for an institutional user" do
  	let(:user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: institution.pid) }
    let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: institution) }
    it { should_not permit(:create) }
    it { should_not permit(:new) }
    it { should_not permit(:show) }
    it { should_not permit(:update) }    
    it { should_not permit(:edit) }
    it { should_not permit(:destroy) }
  end
  
	context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
    it { should_not permit(:create) }
    it { should_not permit(:new) }
    it { should_not permit(:show) }
    it { should_not permit(:update) }    
    it { should_not permit(:edit) }
    it { should_not permit(:destroy) }
  end	
end