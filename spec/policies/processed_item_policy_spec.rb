require 'spec_helper'

describe ProcessedItemPolicy do
	subject (:processed_item_policy) { ProcessedItemPolicy.new(user, processed_item) }
	let(:institution) { FactoryGirl.create(:institution) }
    
  context "for an admin user" do
  	let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
    let(:processed_item) { FactoryGirl.create(:processed_item)}

    it { should permit(:create) }
    it { should permit(:new) }
    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:edit) }
    it { should permit(:mark_as_reviewed)}
    it { should_not permit(:destroy) }
  end

  context "for an institutional admin user" do
  	let(:user) { FactoryGirl.create(:user, :institutional_admin, 
                                     institution_pid: institution.pid) }
    describe "when the item is" do
      describe "in my institution" do
        let(:processed_item) { FactoryGirl.create(:processed_item, institution: institution.identifier) }
        it { should_not permit(:create) }
        it { should_not permit(:new) }
        it { should permit(:show) }
        it { should permit(:update) }
        it { should permit(:edit) }
        it { should permit(:mark_as_reviewed)}
        it { should_not permit(:destroy) } 
      end

      describe "not in my institution" do
        let(:processed_item) { FactoryGirl.create(:processed_item)}
        it { should_not permit(:show) }
        it { should_not permit(:update) }
        it { should_not permit(:edit) }
        it { should_not permit(:mark_as_reviewed) }
        it { should_not permit(:destroy) } 	
      end
    end
  end

  context "for an institutional user" do
  	let(:user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: institution.pid) }
    describe "when the item is" do
      describe "in my institution" do
        let(:processed_item) { FactoryGirl.create(:processed_item, institution: institution.identifier) }
    		it { should_not permit(:create) }
    		it { should_not permit(:new) }
    		it { should permit(:show) }
    		it { should_not permit(:update) }    
    		it { should_not permit(:edit) }
    		it { should_not permit(:mark_as_reviewed) }
    		it { should_not permit(:destroy) }
    	end

    	describe "not in my institution" do
        let(:processed_item) { FactoryGirl.create(:processed_item)}
        it { should_not permit(:show) }
        it { should_not permit(:update) }
        it { should_not permit(:edit) }
        it { should_not permit(:mark_as_reviewed) }
        it { should_not permit(:destroy) } 	
      end
    end
  end
  
  context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    let(:processed_item) { FactoryGirl.create(:processed_item)}
    it { should_not permit(:create) }
    it { should_not permit(:new) }
    it { should_not permit(:show) }
    it { should_not permit(:update) }    
    it { should_not permit(:edit) }
    it { should_not permit(:mark_as_reviewed) }
    it { should_not permit(:destroy) }
  end 
end