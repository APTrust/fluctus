require 'spec_helper'

describe ProcessedItemPolicy do
	subject (:processed_item_policy) { ProcessedItemPolicy.new(user, processed_item) }
	let(:institution) { FactoryGirl.create(:institution) }
    
  context 'for an admin user' do
  	let(:user) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
    let(:processed_item) { FactoryGirl.create(:processed_item)}

    it do
      should permit(:create)
      should permit(:new) 
      should permit(:show)
      should permit(:update)
      should permit(:edit)
      should permit(:mark_as_reviewed)
      should_not permit(:destroy)
    end
  end

  context 'for an institutional admin user' do
  	let(:user) { FactoryGirl.create(:user, :institutional_admin, 
                                     institution_pid: institution.pid) }
    describe 'when the item is' do
      describe 'in my institution' do
        let(:processed_item) { FactoryGirl.create(:processed_item, institution: institution.identifier) }
        it do
          should_not permit(:create)
          should_not permit(:new)
          should permit(:show)
          should permit(:update)
          should permit(:edit)
          should permit(:mark_as_reviewed)
          should_not permit(:destroy)
        end
      end

      describe 'not in my institution' do
        let(:processed_item) { FactoryGirl.create(:processed_item)}
        it do
          should_not permit(:create)
          should_not permit(:new)
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:mark_as_reviewed)
          should_not permit(:destroy)	
        end
      end
    end
  end

  context 'for an institutional user' do
  	let(:user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: institution.pid) }
    describe 'when the item is' do
      describe 'in my institution' do
        let(:processed_item) { FactoryGirl.create(:processed_item, institution: institution.identifier) }
    		it do
          should_not permit(:create)
      		should_not permit(:new)
      		should permit(:show) 
      		should_not permit(:update)    
      		should_not permit(:edit)
      		should_not permit(:mark_as_reviewed)
      		should_not permit(:destroy)
        end
    	end

    	describe 'not in my institution' do
        let(:processed_item) { FactoryGirl.create(:processed_item)}
        it do
          should_not permit(:create)
          should_not permit(:new) 
          should_not permit(:show)
          should_not permit(:update)
          should_not permit(:edit)
          should_not permit(:mark_as_reviewed)
          should_not permit(:destroy) 
        end	
      end
    end
  end
  
  context 'for an authenticated user without a user group' do
    let(:user) { FactoryGirl.create(:user) }
    let(:processed_item) { FactoryGirl.create(:processed_item)}
    it do
      should_not permit(:create)
      should_not permit(:new)
      should_not permit(:show)
      should_not permit(:update)    
      should_not permit(:edit)
      should_not permit(:mark_as_reviewed)
      should_not permit(:destroy)
    end
  end 
end