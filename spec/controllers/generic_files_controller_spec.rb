require 'spec_helper'

describe GenericFilesController do
  let(:user) { FactoryGirl.create(:user, :admin) }
  let(:file) { FactoryGirl.create(:generic_file) }

  before do
    GenericFile.delete_all
    IntellectualObject.delete_all
    Institution.delete_all
  end

  after :all do
    GenericFile.delete_all
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


  describe "POST #create" do
    after do
      obj1.destroy
    end
    describe "when not signed in" do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      it "should redirect to login" do
        post :create, intellectual_object_id: obj1, intellectual_object: {title: 'Foo' }
        expect(response).to redirect_to root_url
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
      end
    end

    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution_id: user.institution_pid) }
      before { sign_in user }
        
      describe "and assigning to an object you don't have access to" do
        let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
        it "should be forbidden" do
          post :create, intellectual_object_id: obj1, generic_file: {uri: 'path/within/bag', size: 12314121, created: '2001-12-31', modified: '2003-03-13', format: 'text/html', checksum_attributes: [{digest: "123ab13df23", algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
          expect(response.code).to eq "403" # forbidden
          expect(JSON.parse(response.body)).to eq({"status"=>"error","message"=>"You are not authorized to access this page."})
         end
      end

      it "should show errors" do
        post :create, intellectual_object_id: obj1, generic_file: {foo: 'bar'}, format: 'json'
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq( {
          "checksum" => ["can't be blank"],
          "created" => ["can't be blank"],
          "format" => ["can't be blank"],
          "modified" => ["can't be blank"],
          "size" => ["can't be blank"],
          "uri" => ["can't be blank"]})
      end

      it "should update fields" do
        # and the parent's solr document should have been updated (but it's not stored, so we can't query it)
        #IntellectualObject.any_instance.should_receive(:update_index)
        post :create, intellectual_object_id: obj1, generic_file: {uri: 'path/within/bag', content_uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg', size: 12314121, created: '2001-12-31', modified: '2003-03-13', format: 'text/html', checksum_attributes: [{digest: "123ab13df23", algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'path/within/bag'
          expect(file.content.dsLocation).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg'
        end
      end
    end
  end
end
