require 'spec_helper'

describe ProcessedItemController do
  let(:institution) { FactoryGirl.create(:institution) }
  let(:admin_user) { FactoryGirl.create(:user, :admin) }
  let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin, institution_pid: institution.id) }

  let!(:item) { FactoryGirl.create(:processed_item, action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'], status: Fluctus::Application::FLUCTUS_STATUSES['success']) }
  let!(:user_item) { FactoryGirl.create(:processed_item, action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'], institution: institution.identifier, status: Fluctus::Application::FLUCTUS_STATUSES['fail']) }

  after do
    ProcessedItem.destroy_all
    Institution.destroy_all
    User.destroy_all
  end

  describe "GET #index" do
    describe "for admin user" do
      before do
        sign_in admin_user
      end

      it "responds successfully with an HTTP 200 status code" do
        get :index
        expect(response).to be_success
      end

      it "renders the index template" do
        get :index
        expect(response).to render_template("index")
      end

      it "assigns the requested institution as @institution" do
        get :index
        assigns(:institution).should eq( admin_user.institution)
      end

      it "assigns @counts" do
        get :index
        assigns(:counts).should include(Fluctus::Application::FLUCTUS_ACTIONS['ingest'])
      end

    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
      end

      it "assigns the requested items as @items" do
        get :index
        assigns(:items).should include(user_item)
      end

      it "assigns @counts" do
        get :index
        assigns(:counts).should include(Fluctus::Application::FLUCTUS_ACTIONS['ingest'])
      end

    end
  end

  describe "GET #show" do
    describe "for admin user" do
      before do
        sign_in admin_user
      end
      it "responds successfully with an HTTP 200 status code" do
        get :show, id: item.id
        expect(response).to be_success
      end

      it "renders the show template" do
        get :show, id: item.id
        expect(response).to render_template("show")
      end

      it "assigns the requested item as @processed_item" do
        get :show, id: item.id
        assigns(:processed_item).id.should eq(item.id)
      end

      it "assigns the requested institution as @institution" do
        get :show, id: item.id
        assigns(:institution).should eq( admin_user.institution)
      end

      it "returns 404, not 500, for item not found" do
        expect {
          get :show,
          etag: "does not exist",
          name: "duznot igzist",
          bag_date: "1901-01-01" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end


  describe "GET #get_reviewed" do
    describe "for admin user" do
      before do
        sign_in admin_user
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['record'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['success'],
                                 reviewed: true)
      end

      it "responds successfully with an HTTP 200 status code" do
        get :get_reviewed, format: :json
        expect(response).to be_success
      end

      it "assigns the correct @items" do
        get :get_reviewed, format: :json
        expect(assigns(:items).count).to eq(ProcessedItem.count)
      end

    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['record'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['success'],
                                 reviewed: true)
      end

      it "assigns the requested items as @items" do
        get :get_reviewed, format: :json
        assigns(:items).should include(user_item)
        expect(assigns(:items).count).to eq(1)
      end
    end
  end


  describe "GET #items_for_restore" do
    describe "for admin user" do
      before do
        sign_in admin_user
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['restore'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 retry: true)
      end

      it "responds successfully with an HTTP 200 status code" do
        get :items_for_restore, format: :json
        expect(response).to be_success
      end

      it "assigns the correct @items" do
        get :items_for_restore, format: :json
        expect(assigns(:items).count).to eq(ProcessedItem.count)
      end

      it "does not include items where retry == false" do
        ProcessedItem.update_all(retry: false)
        get :items_for_restore, format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
        2.times { FactoryGirl.create(:processed_item) }
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['restore'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 institution: institutional_admin.institution.identifier,
                                 retry: true)

      end

      it "assigns the requested items as @items" do
        get :items_for_restore, format: :json
        assigns(:items).should include(user_item)
        expect(assigns(:items).count).to eq(ProcessedItem.count)
      end
    end

    describe "with object_identifier param" do
      before do
        3.times do
          FactoryGirl.create(:processed_item, action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'])
        end
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['restore'],
                                 institution: institution.identifier,
                                 retry: true)
        ProcessedItem.all.limit(2).update_all(object_identifier: "mickey/mouse")
        sign_in institutional_admin
      end

      it "should return only items with the specified object_identifier" do
        get :items_for_restore, object_identifier: "mickey/mouse", format: :json
        expect(assigns(:items).count).to eq(2)
      end
    end
  end

  describe "GET #items_for_dpn" do
    describe "for admin user" do
      before do
        sign_in admin_user
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['dpn'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 retry: true)
      end

      it "responds successfully with an HTTP 200 status code" do
        get :items_for_dpn, format: :json
        expect(response).to be_success
      end

      it "assigns the correct @items" do
        get :items_for_dpn, format: :json
        expect(assigns(:items).count).to eq(ProcessedItem.count)
      end

      it "does not include items where retry == false" do
        ProcessedItem.update_all(retry: false)
        get :items_for_dpn, format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
        2.times { FactoryGirl.create(:processed_item) }
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['dpn'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 institution: institutional_admin.institution.identifier,
                                 retry: true)

      end

      it "assigns the requested items as @items" do
        get :items_for_dpn, format: :json
        assigns(:items).should include(user_item)
        expect(assigns(:items).count).to eq(ProcessedItem.count)
      end
    end

    describe "with object_identifier param" do
      before do
        3.times do
          FactoryGirl.create(:processed_item, action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'])
        end
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['dpn'],
                                 institution: institution.identifier,
                                 retry: true)
        ProcessedItem.all.limit(2).update_all(object_identifier: "mickey/mouse")
        sign_in institutional_admin
      end

      it "should return only items with the specified object_identifier" do
        get :items_for_dpn, object_identifier: "mickey/mouse", format: :json
        expect(assigns(:items).count).to eq(2)
      end
    end
  end


  describe "GET #items_for_delete" do
    describe "for admin user" do
      before do
        sign_in admin_user
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['delete'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 retry: true)
      end

      it "responds successfully with an HTTP 200 status code" do
        get :items_for_delete, format: :json
        expect(response).to be_success
      end

      it "assigns the correct @items" do
        get :items_for_delete, format: :json
        expect(assigns(:items).count).to eq(ProcessedItem.count)
      end

      it "does not include items where retry == false" do
        ProcessedItem.update_all(retry: false)
        get :items_for_delete, format: :json
        expect(assigns(:items).count).to eq(0)
      end

    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
        2.times { FactoryGirl.create(:processed_item) }
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['delete'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 institution: institutional_admin.institution.identifier,
                                 retry: true)
      end

      it "assigns the requested items as @items" do
        get :items_for_delete, format: :json
        assigns(:items).should include(user_item)
        expect(assigns(:items).count).to eq(ProcessedItem.count)
      end
    end

    describe "with object_identifier param" do
      before do
        3.times do
          FactoryGirl.create(:processed_item,
                             action: Fluctus::Application::FLUCTUS_ACTIONS['delete'],
                             stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                             status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                             institution: institutional_admin.institution.identifier,
                             object_identifier: "mickey/mouse",
                             generic_file_identifier: "mickey/mouse/club",
                             retry: true)
        end
        pi = ProcessedItem.last
        pi.generic_file_identifier = "something/else"
        pi.save
        sign_in institutional_admin
      end

      it "should return only items with the specified object_identifier" do
        get :items_for_delete, generic_file_identifier: "mickey/mouse/club", format: :json
        expect(assigns(:items).count).to eq(2)
      end
    end
  end



  describe "POST #delete_test_items" do
    before do
      sign_in admin_user
      5.times do
        FactoryGirl.create(:processed_item, institution: "test.edu")
      end
    end
    after do
      ProcessedItem.where(institution: "test.edu").delete_all
    end

    it "should return only items with the specified object_identifier" do
      post :delete_test_items, format: :json
      expect(ProcessedItem.where(institution: "test.edu").count).to eq 0
    end
  end


  describe "POST #set_restoration_status" do
    describe "for admin user" do
      before do
        sign_in admin_user
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['restore'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 retry: false,
                                 object_identifier: "ned/flanders")
      end

      it "responds successfully with an HTTP 200 status code" do
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Lightyear', retry: true,
             use_route: 'item_set_restoration_status')
        expect(response).to be_success
      end

      it "assigns the correct @item" do
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Buzz', retry: true,
             use_route: 'item_set_restoration_status')
        expected_item = ProcessedItem.where(object_identifier: 'ned/flanders').order(created_at: :desc).first
        expect(assigns(:item).id).to eq(expected_item.id)
      end

      it "updates the correct @item" do
        ProcessedItem.first.update(object_identifier: "homer/simpson")
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Aldrin', retry: true,
             use_route: 'item_set_restoration_status')
        update_count = ProcessedItem.where(object_identifier: 'ned/flanders',
                                           stage: 'Resolve', status: 'Success', retry: true).count
        expect(update_count).to eq(1)
      end

      it "returns 404 for no matching records" do
        ProcessedItem.update_all(object_identifier: "homer/simpson")
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Neil', retry: true,
             use_route: 'item_set_restoration_status')
        expect(response.status).to eq(404)
      end

      it "returns 400 for bad request" do
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Invalid_Stage', status: 'Invalid_Status', note: 'Armstrong', retry: true,
             use_route: 'item_set_restoration_status')
        expect(response.status).to eq(400)
      end
    end

    describe "for admin user - with duplicate entries" do
      before do
        sign_in admin_user
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['restore'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 retry: false,
                                 object_identifier: "ned/flanders",
                                 etag: "12345678")
      end

      # PivotalTracker #93375060
      # All Processed Items now have the same identifier and etag.
      # When we update the restoration record, it should update only one
      # record (the latest). None of the older restore requests should
      # be touched.
      it "updates the correct @items" do
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', note: 'Aldrin', retry: true,
             use_route: 'item_set_restoration_status')
        update_count = ProcessedItem.where(object_identifier: 'ned/flanders',
                                           stage: 'Resolve', status: 'Success', retry: true).count
        # Should be only one item updated...
        expect(update_count).to eq(1)
        # ... and it should be the most recent
        restore_items = ProcessedItem.where(object_identifier: 'ned/flanders',
                        action: Fluctus::Application::FLUCTUS_ACTIONS['restore']).order(created_at: :desc)
        restore_items.each_with_index do |item, index|
          if index == 0
            # first item should be updated
            expect(item.status).to eq('Success')
          else
            # all other items should not be updated
            expect(item.status).to eq(Fluctus::Application::FLUCTUS_STATUSES['pend'])
          end
        end
      end
    end
  end



  describe "Post #create" do
    describe "for admin user" do
      let (:attributes) { FactoryGirl.attributes_for(:processed_item) }
      before do
        sign_in admin_user
      end

      after do
        ProcessedItem.delete_all
      end

      it "should reject no parameters" do
        expect {
          post :create, {}
        }.to raise_error ActionController::ParameterMissing
      end

      it 'should reject a status, stage or action that is not allowed' do
        post :create, processed_item: {name: "123456.tar", etag: "1234567890", bag_date: Time.now.utc, user: "Kelly Croswell", institution: institution.identifier,
                                       bucket: "aptrust.receiving.#{institution.identifier}", date: Time.now.utc, note: "Note", action: "File",
                                       stage: "Entry", status: "Finalized", outcome: "Outcome", reviewed: false}, format: 'json'
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq( { "status" => ["Status is not one of the allowed options"],
                                                   "stage" => ["Stage is not one of the allowed options"],
                                                   "action" => ["Action is not one of the allowed options"]})
      end

      it 'should accept good parameters via json' do
        expect {
          post :create, processed_item: {name: "123456.tar", etag: "1234567890", bag_date: Time.now.utc, user: "Kelly Croswell", institution: institution.identifier,
                                         bucket: "aptrust.receiving.#{institution.identifier}", date: Time.now.utc, note: "Note", action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'],
                                         stage: Fluctus::Application::FLUCTUS_STAGES['fetch'], status: Fluctus::Application::FLUCTUS_STATUSES['fail'], outcome: "Outcome", reviewed: false}, format: 'json'
        }.to change(ProcessedItem, :count).by(1)
        expect(response.status).to eq(201)
        assigns[:processed_item].should be_kind_of ProcessedItem
        expect(assigns(:processed_item).name).to eq '123456.tar'
      end

      it 'should fix an item with a null reviewed flag' do
        post :create, processed_item: {name: "123456.tar", etag: "1234567890", bag_date: Time.now.utc, user: "Kelly Croswell", institution: institution.identifier,
                                       bucket: "aptrust.receiving.#{institution.identifier}", date: Time.now.utc, note: "Note", action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'],
                                       stage: Fluctus::Application::FLUCTUS_STAGES['fetch'], status: Fluctus::Application::FLUCTUS_STATUSES['fail'], outcome: "Outcome", reviewed: nil}, format: 'json'
        expect(response.status).to eq(201)
        assigns[:processed_item].should be_kind_of ProcessedItem
        expect(assigns(:processed_item).reviewed).to eq(false)
      end
    end
  end

  describe "Post #handle_selected" do
    describe "as admin user" do
      let!(:processing_item) { FactoryGirl.create(:processed_item, action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'], status: Fluctus::Application::FLUCTUS_STATUSES['start']) }
      let(:item_id) { "r_#{item.id}" }
      let(:proc_id) { "r_#{processing_item.id}" }
      before do
        sign_in admin_user
      end

      after do
        ProcessedItem.delete_all
      end

      it "should update an item's review field to true" do
        post :handle_selected, review: [item_id], format: 'js'
        expect(response.status).to eq(200)
        ProcessedItem.find(item.id).reviewed.should eq(true)
      end

      it "should not review a processing item" do
        post :handle_selected, review: [proc_id], format: 'js'
        expect(response.status).to eq(200)
        ProcessedItem.find(processing_item.id).reviewed.should eq(false)
      end
    end

    describe "as institutional_admin" do
      let(:user_id) { "r_#{user_item.id}" }
      before do
        sign_in institutional_admin
      end

      after do
        ProcessedItem.delete_all
      end

      it "should update an item's review field to true" do
        post :handle_selected, review: [user_id], format: 'js'
        expect(response.status).to eq(200)
        ProcessedItem.find(user_item.id).reviewed.should eq(true)
      end
    end

  end

  describe "Post #review_all" do
    let!(:failed_item) { FactoryGirl.create(:processed_item, action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'], status: Fluctus::Application::FLUCTUS_STATUSES['fail']) }
    let!(:second_item) { FactoryGirl.create(:processed_item, action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'], status: Fluctus::Application::FLUCTUS_STATUSES['fail'], bucket: "aptrust.receiving.#{institution.identifier}", institution: institution.identifier) }
    describe "as admin user" do
      before do
        sign_in admin_user
        session[:purge_datetime] = Time.now.utc
      end

      after do
        ProcessedItem.delete_all
      end

      it "should reset the purge datetime in the session variable" do
        time_before = session[:purge_datetime]
        post :review_all
        session[:purge_datetime].should_not eq(time_before)
      end

      it "should update all item's review fields to true" do
        post :review_all
        expect(response.status).to eq(302)
        ProcessedItem.find(failed_item.id).reviewed.should eq(true)
      end
    end

    describe "as institutional admin user" do
      before do
        sign_in institutional_admin
        session[:purge_datetime] = Time.now.utc
      end

      it "should update all items associated with user's institution's review fields to true" do
        post :review_all
        expect(response.status).to eq(302)
        ProcessedItem.find(second_item.id).reviewed.should eq(true)
      end

    end
  end

  describe "GET #ingested_since" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before do
      10.times do FactoryGirl.create(:ingested_item) end
      sign_in user
      get :show, id: item.id
    end

    after do
      ProcessedItem.delete_all
    end

    it 'admin can get items ingested since' do
      get :ingested_since, since: '2009-01-01', format: :json
      expect(response).to be_successful
      expect(assigns(:items).length).to eq 10
    end

    it 'missing date causes error' do
      expected = { 'error' => 'Param since must be a valid datetime' }.to_json
      get :ingested_since, since: '', format: :json
      expect(response.status).to eq 400
      expect(response.body).to eq expected
    end

  end

  describe "Search" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before do
      ProcessedItem.delete_all
    end

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :index, institution_id: 'apt:123'
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when some objects are in the repository and signed in' do
      let!(:item1) { FactoryGirl.create(:processed_item, name: '1234567890.tar', etag: '3') }
      let!(:item2) { FactoryGirl.create(:processed_item, name: '1238907543.tar', etag: '4') }
      let!(:item3) { FactoryGirl.create(:processed_item, name: '1', etag: '1548cdbe82348bdd32mds') }
      let!(:item4) { FactoryGirl.create(:processed_item, name: '2', etag: '23045ldk2383xd320932k') }
      before { sign_in user }
      it 'should bring back all objects on an * search' do
        get :search, search_field: 'All Fields', qq: '*'
        expect(response).to be_successful
        expect(assigns(:processed_items).map &:id).to match_array [item1.id, item2.id, item3.id, item4.id]
      end

      it 'should match a partial search on name' do
        get :search, search_field: 'Name', qq: '123'
        expect(response).to be_successful
        expect(assigns(:processed_items).map &:id).to match_array [item1.id, item2.id]
      end

      it 'should match an exact search on name' do
        get :search, search_field: 'Name', qq: '1238907543.tar'
        expect(response).to be_successful
        expect(assigns(:processed_items).map &:id).to match_array [item2.id]
      end

      it 'should match a partial search on etag' do
        get :search, search_field: 'Etag', qq: '32'
        expect(response).to be_successful
        expect(assigns(:processed_items).map &:id).to match_array [item3.id, item4.id]
      end

      it 'should match an exact search on etag' do
        get :search, search_field: 'Etag', qq: '1548cdbe82348bdd32mds'
        expect(response).to be_successful
        expect(assigns(:processed_items).map &:id).to match_array [item3.id]
      end
    end
  end

  describe "GET #api_search" do
    let!(:item1) { FactoryGirl.create(:processed_item,
                                      name: 'item1.tar',
                                      etag: 'etag1',
                                      institution: 'inst1',
                                      retry: true,
                                      reviewed: false,
                                      bag_date: '2014-10-17 14:56:56Z',
                                      action: 'Ingest',
                                      stage: 'Record',
                                      status: 'Success',
                                      object_identifier: 'test.edu/item1',
                                      generic_file_identifier: 'test.edu/item1/file1.pdf') }

    describe "for admin user" do
      before do
        sign_in admin_user
      end

      it "returns all records when no criteria specified" do
        get :api_search, format: :json
        assigns(:items).should include(user_item)
        assigns(:items).should include(item)
        assigns(:items).should include(item1)
      end

      # Note: Use strings for true/false, as we'd get in a web
      # request, or SQLite search fails. Also be sure to include
      # the Z at the end of the bag_date string.
      it "filters down to the right records" do
        get(:api_search, format: :json, name: 'item1.tar',
            etag: 'etag1', institution: 'inst1',
            retry: 'true', reviewed: 'false',
            bag_date: '2014-10-17 14:56:56Z',
            action: 'Ingest', stage: 'Record',
            status: 'Success', object_identifier: 'test.edu/item1',
            generic_file_identifier: 'test.edu/item1/file1.pdf')
        assigns(:items).should_not include(user_item)
        assigns(:items).should_not include(item)
        assigns(:items).should include(item1)
      end

    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
      end

      it "assigns the requested items as @items" do
        get :api_search, format: :json
        assigns(:items).should include(user_item)
        assigns(:items).should_not include(item)
      end
    end
  end

end
