require 'spec_helper'

describe GenericFilePolicy do
  subject (:generic_file_policy) { GenericFilePolicy.new(user, generic_file) }
	let(:institution) { FactoryGirl.create(:institution) }
    
  context "for an admin user" do
  	let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
    let(:generic_file) { FactoryGirl.create(:generic_file)}

    it { should permit(:create) }
    it { should permit(:add_event)}
    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:edit) }
    it { should permit(:soft_delete) }
    it { should_not permit(:destroy) }
  end

  context "for an institutional admin user" do
  	let(:user) { FactoryGirl.create(:user, :institutional_admin, 
                                     institution_pid: institution.pid) }
    describe "when the file is" do
      describe "in my institution" do
        let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: institution) }
        let(:generic_file) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object) }
        it { should_not permit(:create) }
        it { should permit(:show) }
        it { should permit(:soft_delete) }
        it { should permit(:add_event) }
        it { should_not permit(:update) }
        it { should_not permit(:edit) }
        it { should_not permit(:destroy) } 
      end

      describe "not in my institution" do
        let(:intellectual_object) { FactoryGirl.create(:institutional_intellectual_object) }
        let(:generic_file) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object) }
      
        it { should_not permit(:create) }
        it { should_not permit(:add_event) }
        it { should_not permit(:show) }
        it { should_not permit(:update) }
        it { should_not permit(:edit) }
        it { should_not permit(:soft_delete) }
        it { should_not permit(:destroy) } 	
      end
    end
  end

  context "for an institutional user" do
  	let(:user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: institution.pid) }
    let(:intellectual_object) { FactoryGirl.create(:consortial_intellectual_object, institution: institution) }
    let(:generic_file) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object) }
    it { should_not permit(:create) }
    it { should_not permit(:add_event) }
    it { should permit(:show) }
    it { should_not permit(:update) }    
    it { should_not permit(:edit) }
    it { should_not permit(:soft_delete) }
    it { should_not permit(:destroy) }

    let(:intellectual_object) { FactoryGirl.create(:institutional_intellectual_object,
                                       institution: institution) }
    let(:generic_file) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object) }
    it { should permit(:show) }
    let(:intellectual_object) { FactoryGirl.create(:restricted_intellectual_object,
                                       institution: institution) }
    let(:generic_file) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object) }
    it { should_not permit(:show) }
  end
  
  context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    let(:generic_file) { FactoryGirl.create(:generic_file)}
    it { should_not permit(:create) }
    it { should_not permit(:new) }
    it { should_not permit(:show) }
    it { should_not permit(:update) }    
    it { should_not permit(:edit) }
    it { should_not permit(:soft_delete) }
    it { should_not permit(:destroy) }
  end 
end