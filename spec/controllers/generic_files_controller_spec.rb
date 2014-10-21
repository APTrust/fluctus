require 'spec_helper'

describe GenericFilesController do
  let(:user) { FactoryGirl.create(:user, :admin, institution_pid: @institution.pid) }
  let(:file) { FactoryGirl.create(:generic_file) }

  before(:all) do
    @institution = FactoryGirl.create(:institution)
    @another_institution = FactoryGirl.create(:institution)
    @intellectual_object = FactoryGirl.create(:consortial_intellectual_object, institution_id: @institution.id)
    GenericFile.delete_all
  end

  after(:all) do
    GenericFile.delete_all
  end

  describe "GET #index" do
    before do
      sign_in user
      file.premisEvents.events_attributes = [
          FactoryGirl.attributes_for(:premis_event_ingest),
          FactoryGirl.attributes_for(:premis_event_fixity_generation)
      ]
      file.save!
      get :show, id: file.pid
    end

    it 'can index files by intel obj identifier' do
      get :index, intellectual_object_identifier: URI.encode(@intellectual_object.identifier), format: :json
      expect(response).to be_successful
      expect(assigns(:intellectual_object)).to eq @intellectual_object
    end

    it 'returns only active files' do
      FactoryGirl.create(:generic_file, intellectual_object: @intellectual_object, identifier: 'one', state: 'A')
      FactoryGirl.create(:generic_file, intellectual_object: @intellectual_object, identifier: 'two', state: 'D')
      get :index, intellectual_object_identifier: URI.encode(@intellectual_object.identifier), format: :json
      expect(response).to be_successful
      response_data = JSON.parse(response.body)
      expect(response_data.select{|f| f['state'] == 'A'}.count).to eq 2
      expect(response_data.select{|f| f['state'] != 'A'}.count).to eq 0
    end

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
          post :create, intellectual_object_id: obj1, generic_file: {uri: 'path/within/bag', size: 12314121, created: '2001-12-31', modified: '2003-03-13', file_format: 'text/html', checksum_attributes: [{digest: "123ab13df23", algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
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
          "file_format" => ["can't be blank"],
          "identifier" => ["can't be blank"],
          "modified" => ["can't be blank"],
          "size" => ["can't be blank"],
          "uri" => ["can't be blank"]})
      end

      it "should update fields" do
        # and the parent's solr document should have been updated (but it's not stored, so we can't query it)
        #IntellectualObject.any_instance.should_receive(:update_index)
        post :create, intellectual_object_id: obj1, generic_file: {uri: 'path/within/bag', content_uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg', size: 12314121, created: '2001-12-31', modified: '2003-03-13', file_format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/puppy.jpg', checksum_attributes: [{digest: "123ab13df23", algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'path/within/bag'
          expect(file.content.dsLocation).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/puppy.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/puppy.jpg'
        end
      end

      it "should add generic file using API identifier" do
        identifier = URI.escape(obj1.identifier)
        post :create, intellectual_object_identifier: identifier, generic_file: {uri: 'path/within/bag', content_uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/cat.jpg', size: 12314121, created: '2001-12-31', modified: '2003-03-13', file_format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/cat.jpg', checksum_attributes: [{digest: "123ab13df23", algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'path/within/bag'
          expect(file.content.dsLocation).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/cat.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/cat.jpg'
        end
      end

      it "should create generic files larger than 2GB" do
        identifier = URI.escape(obj1.identifier)
        post :create, intellectual_object_identifier: identifier, generic_file: {uri: 'path/within/dog', content_uri: 'http://s3-eu-west-1.amazonaws.com/mybucket/dog.jpg', size: 300000000000, created: '2001-12-31', modified: '2003-03-13', file_format: 'text/html', identifier: 'test.edu/12345678/data/mybucket/dog.jpg', checksum_attributes: [{digest: "123ab13df23", algorithm: 'MD6', datetime: '2003-03-13T12:12:12Z'}]}, format: 'json'
        expect(response.code).to eq '201'
        assigns(:generic_file).tap do |file|
          expect(file.uri).to eq 'path/within/dog'
          expect(file.content.dsLocation).to eq 'http://s3-eu-west-1.amazonaws.com/mybucket/dog.jpg'
          expect(file.identifier).to eq 'test.edu/12345678/data/mybucket/dog.jpg'
        end
      end

    end
  end

  describe "POST #create_batch" do
      describe "when not signed in" do
        let(:obj1) { @intellectual_object }
        it "should show unauthorized" do
          post(:create_batch, intellectual_object_id: obj1.id, generic_files: [],
               format: 'json', use_route: 'generic_file_create_batch')
          expect(response.code).to eq "401" # unauthorized
        end
      end

      describe "when signed in" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: @institution.pid) }
        let(:obj2) { FactoryGirl.create(:consortial_intellectual_object, institution_id: @another_institution.id) }
        let(:batch_obj) { FactoryGirl.create(:consortial_intellectual_object, institution_id: @institution.id) }
        let(:current_dir) { File.dirname(__FILE__) }
        let(:json_file) { File.join(current_dir, "..", "fixtures", "generic_file_batch.json") }
        let(:raw_json) { File.read(json_file) }
        let(:gf_data) { JSON.parse(raw_json) }

        before { sign_in user }

        describe "and assigning to an object you don't have access to" do
          it "should be forbidden" do
            post(:create_batch, intellectual_object_id: obj2.id, generic_files: [],
                 format: 'json', use_route: 'generic_file_create_batch')
            expect(response.code).to eq "403" # forbidden
            expect(JSON.parse(response.body)).to eq({"status"=>"error", "message"=>"You are not authorized to access this page."})
          end
        end

        # Loading test data from a fixture, because there there doesn't seem
        # to be any direct method of creating a PremisEvent without saving it
        # as well (see GenericFile.add_event). We need to save some files with
        # new, unsaved PremisEvents.
        describe "and assigning to an object you do have access to" do
          it 'it should save multiple files and their events' do
            post(:create_batch, intellectual_object_id: batch_obj.id, generic_files: gf_data,
                 format: 'json', use_route: 'generic_file_create_batch')
            expect(response.code).to eq "201"
            expect(JSON.parse(response.body).count).to eq 2
          end
        end

      end
    end

  describe "PATCH #update" do
    before(:all) { @file = FactoryGirl.create(:generic_file, intellectual_object_id: @intellectual_object.id) }
    let(:file) { @file }

    describe "when not signed in" do
      it "should redirect to login" do
        patch :update, intellectual_object_id: file.intellectual_object, id: file.id, trailing_slash: true
        expect(response).to redirect_to root_url + "users/sign_in"
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
      end
    end

    describe "when signed in" do
      before { sign_in user }

      describe "and deleteing a file you don't have access to" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: @another_institution.id) }
        it "should be forbidden" do
          patch :update, intellectual_object_id: file.intellectual_object, id: file.id, generic_file: {size: 99}, format: 'json', trailing_slash: true
          expect(response.code).to eq "403" # forbidden
          expect(JSON.parse(response.body)).to eq({"status"=>"error","message"=>"You are not authorized to access this page."})
         end
      end

      describe "and you have access to the file" do
        it "should update the file" do
          patch :update, intellectual_object_id: file.intellectual_object, id: file.id, generic_file: {size: 99}, format: 'json', trailing_slash: true
          expect(assigns[:generic_file].size).to eq 99
          expect(response.code).to eq '204'
        end

        it "should update the file by identifier (API)" do
          patch :update, identifier: URI.escape(file.identifier), id: file.id, generic_file: {size: 99}, format: 'json', trailing_slash: true
          expect(assigns[:generic_file].size).to eq 99
          expect(response.code).to eq '204'
        end

      end
    end
  end

  describe "DELETE #destroy" do
    before(:all) {
      @file = FactoryGirl.create(:generic_file, intellectual_object_id: @intellectual_object.id)
      @parent_processed_item = FactoryGirl.create(:processed_item,
                                                  object_identifier: @intellectual_object.identifier,
                                                  action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'],
                                                  stage: Fluctus::Application::FLUCTUS_STAGES['record'],
                                                  status: Fluctus::Application::FLUCTUS_STATUSES['success'])
    }
    let(:file) { @file }

    after(:all) {
      @parent_processed_item.delete
    }

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

        it "should create a ProcessedItem with the delete request" do
          delete :destroy, id: file, format: 'json'
          pi = ProcessedItem.where(generic_file_identifier: @file.identifier).first
          expect(pi).not_to be_nil
          expect(pi.object_identifier).to eq @intellectual_object.identifier
          expect(pi.action).to eq Fluctus::Application::FLUCTUS_ACTIONS['delete']
          expect(pi.stage).to eq Fluctus::Application::FLUCTUS_STAGES['requested']
          expect(pi.status).to eq Fluctus::Application::FLUCTUS_STATUSES['pend']
        end

      end
    end
  end
end
