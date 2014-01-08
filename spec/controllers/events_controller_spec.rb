require 'spec_helper'

describe EventsController do
  let(:object) { FactoryGirl.create(:intellectual_object, institution: user.institution) }
  let(:file) { FactoryGirl.create(:generic_file, intellectual_object: object) }
  let(:event_attrs) { FactoryGirl.attributes_for(:premis_event_fixity_generation) }


  describe 'signed in as institutional admin' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) }
    before { sign_in user }

    describe 'POST create' do
      it 'creates an event for the generic file' do
        file.premisEvents.events.count.should == 0
        post :create, generic_file_id: file, event: event_attrs
        file.reload

        file.premisEvents.events.count.should == 1
        response.should redirect_to generic_file_path(file)
        assigns(:parent_object).should == file
        assigns(:event).should_not be_nil
        flash[:notice].should =~ /Successfully created new event/
      end

      it 'creates an event for an intellectual object' do
        object.premisEvents.events.count.should == 0
        post :create, intellectual_object_id: object, event: event_attrs
        object.reload

        object.premisEvents.events.count.should == 1
        response.should redirect_to intellectual_object_path(object)
        assigns(:parent_object).should == object
        assigns(:event).should_not be_nil
        flash[:notice].should =~ /Successfully created new event/
      end

      it 'if it fails, it prints a fail message' do
        file.premisEvents.events.count.should == 0
        GenericFile.any_instance.should_receive(:save).and_return(false) # Make it fail
        post :create, generic_file_id: file, event: event_attrs
        file.reload
        file.premisEvents.events.count.should == 0
        flash[:alert].should =~ /Unable to create event/
      end
    end

    describe "POST create a file where you don't have permission" do
      let(:file) { FactoryGirl.create(:generic_file) }

      it 'denies access' do
        file.premisEvents.events.count.should == 0
        post :create, generic_file_id: file, event: event_attrs
        file.reload

        file.premisEvents.events.count.should == 0
        expect(response).to redirect_to root_url
        flash[:alert].should =~ /You are not authorized/
      end
    end
  end


  describe 'not signed in' do
    let(:file) { FactoryGirl.create(:generic_file) }

    describe 'POST create' do
      before do
        post :create, generic_file_id: file, event: event_attrs
      end

      it 'redirects to login' do
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
      end
    end
  end

end
