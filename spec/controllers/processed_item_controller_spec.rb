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
    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
      end

      it "assigns the requested items as @items" do
        get :index
        assigns(:items).should include(user_item)
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

      it "assigns the requested item as @processedItem" do
        get :show, id: item.id
        assigns(:processedItem).id.should eq(item.id)
      end

      it "assigns the requested institution as @institution" do
        get :show, id: item.id
        assigns(:institution).should eq( admin_user.institution)
      end
    end
  end


  describe "GET #get_reviewed" do
    describe "for admin user" do
      before do
        sign_in admin_user
        ProcessedItem.update_all(reviewed: true)
      end

      it "responds successfully with an HTTP 200 status code" do
        get :get_reviewed, format: :json
        expect(response).to be_success
      end

      it "assigns the correct @items" do
        get :get_reviewed, format: :json
        assigns(:items).should have(ProcessedItem.count).items
      end

    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
        ProcessedItem.update_all(reviewed: true)
      end

      it "assigns the requested items as @items" do
        get :get_reviewed, format: :json
        assigns(:items).should include(user_item)
        assigns(:items).should have(1).items
      end
    end
  end


  describe "GET #restore" do
    describe "for admin user" do
      before do
        sign_in admin_user
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['restore'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 retry: true)
      end

      it "responds successfully with an HTTP 200 status code" do
        get :restore, format: :json
        expect(response).to be_success
      end

      it "assigns the correct @items" do
        get :restore, format: :json
        assigns(:items).should have(ProcessedItem.count).items
      end

    end

    describe "for institutional admin" do
      before do
        sign_in institutional_admin
        2.times { FactoryGirl.create(:processed_item) }
        ProcessedItem.update_all(action: Fluctus::Application::FLUCTUS_ACTIONS['restore'],
                                 stage: Fluctus::Application::FLUCTUS_STAGES['requested'],
                                 status: Fluctus::Application::FLUCTUS_STATUSES['pend'],
                                 retry: true)

      end

      it "assigns the requested items as @items" do
        get :restore, format: :json
        assigns(:items).should include(user_item)
        assigns(:items).should have(ProcessedItem.count).items
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
        get :restore, object_identifier: "mickey/mouse", format: :json
        assigns(:items).should have(2).items
      end
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
             stage: 'Resolve', status: 'Success', retry: true, use_route: 'item_set_restoration_status')
        expect(response).to be_success
      end

      it "assigns the correct @items" do
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', retry: true, use_route: 'item_set_restoration_status')
        assigns(:items).should have(ProcessedItem.count).items
      end

      it "updates the correct @items" do
        ProcessedItem.first.update(object_identifier: "homer/simpson")
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', retry: true, use_route: 'item_set_restoration_status')
        update_count = ProcessedItem.where(object_identifier: 'ned/flanders',
                                           stage: 'Resolve', status: 'Success', retry: true).count
        expect(update_count).to eq(ProcessedItem.count - 1)
      end

      it "returns 404 for no matching records" do
        ProcessedItem.update_all(object_identifier: "homer/simpson")
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Resolve', status: 'Success', retry: true, use_route: 'item_set_restoration_status')
        expect(response.status).to eq(404)
      end

      it "returns 400 for bad request" do
        post(:set_restoration_status, format: :json, object_identifier: 'ned/flanders',
             stage: 'Invalid_Stage', status: 'Invalid_Status', retry: true, use_route: 'item_set_restoration_status')
        expect(response.status).to eq(400)
      end

    end
  end



  describe "Post #create" do
    describe "for admin user" do
      let (:attributes) { FactoryGirl.attributes_for(:processed_item) }
      before do
        sign_in admin_user
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

      it "should update an item's review field to true" do
        post :handle_selected, review: [user_id], format: 'js'
        expect(response.status).to eq(200)
        ProcessedItem.find(user_item.id).reviewed.should eq(true)
      end
    end

  end

  describe "Post #review_all" do
    let!(:failed_item) { FactoryGirl.create(:processed_item, action: Fluctus::Application::FLUCTUS_ACTIONS['fixity'], status: Fluctus::Application::FLUCTUS_STATUSES['fail']) }
    describe "as admin user" do
      before do
        sign_in admin_user
        session[:purge_datetime] = Time.now.utc
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
  end

  describe "GET #ingested_since" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before do
      10.times do FactoryGirl.create(:ingested_item) end
      sign_in user
      get :show, id: item.id
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

end
