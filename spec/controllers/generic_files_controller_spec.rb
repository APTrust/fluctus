require 'spec_helper'

describe GenericFilesController do
  let(:user) { FactoryGirl.create(:user, :admin) }
  let(:file) { FactoryGirl.create(:generic_file) }

  before do
    GenericFile.delete_all
    User.delete_all
  end

  after :all do
    GenericFile.delete_all
    User.delete_all
  end

  describe "GET #show" do
    before do
      sign_in user
      file.premisEvents.events_attributes = [
        FactoryGirl.attributes_for(:premis_event_ingest),
        FactoryGirl.attributes_for(:premis_event_fixity_generation)
      ]
      file.save!
      get :show, id: file.pid
    end

    it 'responds successfully' do
      response.should render_template(:show)
      response.should be_successful
    end

    it 'assigns the generic file' do
      assigns(:generic_file).should == file
    end

    it 'assigns events' do
      assigns(:events).count.should == file.premisEvents.events.count
    end
  end

end
