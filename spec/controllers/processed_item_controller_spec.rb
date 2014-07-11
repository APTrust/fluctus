require 'spec_helper'

describe ProcessedItemController do
  #let(:user) { FactoryGirl.create(:user, :admin, institution_pid: @institution.pid) }
  let(:item) { FactoryGirl.create(:processed_item, status: 'Failed') }

  before(:all) do
    #@institution = FactoryGirl.create(:institution)
    10.times do FactoryGirl.create(:ingested_item) end
  end

  after :all do
    ProcessedItem.delete_all
  end

  describe "GET #ingested_since" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before do
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
