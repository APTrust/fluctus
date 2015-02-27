require 'spec_helper'
require 'spec_helper'

describe ProcessedItemPolicy do
	subject (:processed_item_policy) { ProcessedItemPolicy.new(user, processed_item) }
	let(:institution) { FactoryGirl.create(:institution) }
    
  context "for an admin user" do
  	let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
    let(:processed_item) { FactoryGirl.create(:processed_item)}

    it do
      should allow_to(:create)
      should allow_to(:new)
      should allow_to(:show)
      should allow_to(:update)
      should allow_to(:edit)
      should allow_to(:mark_as_reviewed)
      should_not allow_to(:destroy)
    end
  end

  context "for an institutional admin user" do
  	let(:user) { FactoryGirl.create(:user, :institutional_admin, 
                                     institution_pid: institution.pid) }
    describe "when the item is" do
      describe "in my institution" do
        let(:processed_item) { FactoryGirl.create(:processed_item, institution: institution.identifier) }
        it do
          should_not allow_to(:create)
          should_not allow_to(:new)
          should allow_to(:show)
          should allow_to(:update)
          should allow_to(:edit)
          should allow_to(:mark_as_reviewed)
          should_not allow_to(:destroy)
        end
      end

      describe "not in my institution" do
        let(:processed_item) { FactoryGirl.create(:processed_item)}
        it do
          should_not allow_to(:create)
          should_not allow_to(:new)
          should_not allow_to(:show)
          should_not allow_to(:update)
          should_not allow_to(:edit)
          should_not allow_to(:mark_as_reviewed)
          should_not allow_to(:destroy)
        end
      end
    end
  end

  context "for an institutional user" do
  	let(:user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: institution.pid) }
    describe "when the item is" do
      describe "in my institution" do
        let(:processed_item) { FactoryGirl.create(:processed_item, institution: institution.identifier) }
    		it do
          should_not allow_to(:create)
      		should_not allow_to(:new)
      		should allow_to(:show)
      		should_not allow_to(:update)
      		should_not allow_to(:edit)
      		should_not allow_to(:mark_as_reviewed)
      		should_not allow_to(:destroy)
        end
    	end

    	describe "not in my institution" do
        let(:processed_item) { FactoryGirl.create(:processed_item)}
        it do
          should_not allow_to(:create)
          should_not allow_to(:new)
          should_not allow_to(:show)
          should_not allow_to(:update)
          should_not allow_to(:edit)
          should_not allow_to(:mark_as_reviewed)
          should_not allow_to(:destroy)
        end	
      end
    end
  end
  
  context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    let(:processed_item) { FactoryGirl.create(:processed_item)}
    it do
      should_not allow_to(:create)
      should_not allow_to(:new)
      should_not allow_to(:show)
      should_not allow_to(:update)
      should_not allow_to(:edit)
      should_not allow_to(:mark_as_reviewed)
      should_not allow_to(:destroy)
    end
  end 
end