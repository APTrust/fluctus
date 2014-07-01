require 'spec_helper'

describe GenericFilesController do
  let(:user) { FactoryGirl.create(:user, :admin, institution_pid: @institution.pid) }
  let(:file) { FactoryGirl.create(:generic_file) }

  before(:all) do
    @institution = FactoryGirl.create(:institution)
    @another_institution = FactoryGirl.create(:institution)
    @intellectual_object = FactoryGirl.create(:consortial_intellectual_object, institution_id: @institution.id)
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

    it "should show the file by identifier for API users" do
      get :show, identifier: URI.encode(file.identifier), use_route: 'file_by_identifier_path'
      expect(response).to be_successful
      expect(assigns(:generic_file)).to eq file
    end

  end


  describe "POST #create" do
    describe "when not signed in" do
      let(:obj1) { @intellectual_object }
      it "should redirect to login" do
        post :create, intellectual_object_id: obj1, intellectual_object: {title: 'Foo' }
        expect(response).to redirect_to root_url + "users/sign_in"
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
      end
    end

    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: @institution.pid) }
      let(:obj1) { @intellectual_object }
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
          "identifier" => ["can't be blank"],
          "modified" => ["can't be blank"],
          "size" => ["can't be blank"],
          "uri" => ["can't be blank"]})
      end

      it "should update fields" do
        # and the parent's solr document should have been updated (but it's not stored, so we can't query it)
        #IntellectualObject.any_instance.should_receive(:update_index)
        post :create, intellectual_object_id: obj1, generic_file: {uri: 'path/within/bag', content_uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg', size: 12314121, created: '2001-12-31', modified: '2003-03-13', format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/puppy.jpg', checksum_attributes: [{digest: "123ab13df23", algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'path/within/bag'
          expect(file.content.dsLocation).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/puppy.jpg'
        end
      end
    end
  end

  describe "PATCH #update" do
    before(:all) { @file = FactoryGirl.create(:generic_file, intellectual_object_id: @intellectual_object.id) }
    let(:file) { @file }

    describe "when not signed in" do
      it "should redirect to login" do
        patch :update, intellectual_object_id: file.intellectual_object, id: file.uri.sub("file://", ''), trailing_slash: true
        expect(response).to redirect_to root_url + "users/sign_in"
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
      end
    end

    describe "when signed in" do
      before { sign_in user }
        
      describe "and deleteing a file you don't have access to" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: @another_institution.id) }
        it "should be forbidden" do
          patch :update, intellectual_object_id: file.intellectual_object, id: file.uri.sub("file://", ''), generic_file: {size: 99}, format: 'json', trailing_slash: true
          expect(response.code).to eq "403" # forbidden
          expect(JSON.parse(response.body)).to eq({"status"=>"error","message"=>"You are not authorized to access this page."})
         end
      end

      describe "and you have access to the file" do
        it "should delete the file" do
          patch :update, intellectual_object_id: file.intellectual_object, id: file.uri.sub("file://", ''), generic_file: {size: 99}, format: 'json', trailing_slash: true
          expect(assigns[:generic_file].size).to eq 99 
          expect(response.code).to eq '204'
        end
      end
    end
  end

  describe "DELETE #destroy" do
    before(:all) { @file = FactoryGirl.create(:generic_file, intellectual_object_id: @intellectual_object.id) }
    let(:file) { @file }

    describe "when not signed in" do
      it "should redirect to login" do
        delete :destroy, id: file
        expect(response).to redirect_to root_url + "users/sign_in"
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
      end
    end

    describe "when signed in" do
      before { sign_in user }
        
      describe "and deleteing a file you don't have access to" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: @another_institution.id) }
        it "should be forbidden" do
          delete :destroy, id: file, format: 'json'
          expect(response.code).to eq "403" # forbidden
          expect(JSON.parse(response.body)).to eq({"status"=>"error","message"=>"You are not authorized to access this page."})
         end
      end

      describe "and you have access to the file" do
        it "should delete the file" do
          delete :destroy, id: file, format: 'json'
          expect(assigns[:generic_file].state).to eq 'D'
          expect(response.code).to eq '204'
        end

        it 'delete the file with html response' do
          delete :destroy, id: file
          expect(response).to redirect_to intellectual_object_path(file.intellectual_object)
          expect(assigns[:generic_file].state).to eq 'D'
          expect(flash[:notice]).to eq "Delete job has been queued for file: #{file.uri}"
        end
      end
    end
  end
end
