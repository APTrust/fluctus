require 'spec_helper'

describe EventsController do

  before :all do
    Institution.destroy_all
    GenericFile.destroy_all
    IntellectualObject.destroy_all
    solr = ActiveFedora::SolrService.instance.conn
    solr.delete_by_query("*:*", params: { commit: true })
  end

  let(:object) { FactoryGirl.create(:intellectual_object, institution: user.institution) }
  let(:file) { FactoryGirl.create(:generic_file, intellectual_object: object) }
  let(:event_attrs) { FactoryGirl.attributes_for(:premis_event_fixity_generation) }

  # An object and a file from a different institution:
  let(:someone_elses_object) { FactoryGirl.create(:intellectual_object) }
  let(:someone_elses_file) { FactoryGirl.create(:generic_file, intellectual_object: someone_elses_object) }


  describe 'signed in as institutional admin' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) }
    before { sign_in user }

    describe 'GET index' do
      before do
        @event = file.add_event(event_attrs)
        file.save!
        @someone_elses_event = someone_elses_file.add_event(event_attrs)
        someone_elses_file.save!
        get :index, institution_id: file.institution
      end

      it 'shows the events for that institution' do
        assigns(:institution).should == file.institution
        assigns(:document_list).length.should == 1
        assigns(:document_list).map(&:id).should == @event.identifier
      end
    end

    describe "GET index for an institution where you don't have permission" do
      it 'denies access' do
        get :index, institution_id: someone_elses_file.institution
        expect(response).to redirect_to root_url
        flash[:alert].should =~ /You are not authorized/
      end
    end

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
      it 'denies access' do
        someone_elses_file.premisEvents.events.count.should == 0
        post :create, generic_file_id: someone_elses_file, event: event_attrs
        someone_elses_file.reload

        someone_elses_file.premisEvents.events.count.should == 0
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

    describe 'GET index' do
      before do
        get :index, institution_id: file.institution
      end

      it 'redirects to login' do
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
      end
    end
  end

end
