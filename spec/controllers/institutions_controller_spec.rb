require 'spec_helper'

describe InstitutionsController do
  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # InstitutionsController. Be sure to keep this updated too.
  # let(:valid_session) { {} }

  before do
    @user = FactoryGirl.create(:user)
    @institution = @user.institution
  end

  describe "GET #index" do
    describe "for admin users" do 
      before do 
        @user.role_ids = [Role.where(name: 'admin').first.id]
        sign_in @user
      end

      after do
        sign_out @user
        @user.role_ids = []
      end

      it "responds successfully with an HTTP 200 status code" do
        get :index
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "renders the index template" do
        get :index
        expect(response).to render_template("index")
      end

      it "assigns all institutions as @institutions" do
        get :index
        assigns(:institutions).should include(@institution)
      end
    end
  end

  describe "GET #show" do
    describe "for admin user" do 
      before do
        @user.role_ids = [Role.where(name: 'admin').first.id]
        sign_in @user
      end

      after do
        @user.role_ids = []
      end

      it "responds successfully with an HTTP 200 status code" do
        get :show, id: @institution.to_param
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "renders the index template" do
        get :show, id: @institution.to_param
        expect(response).to render_template("show")
      end

      it "assigns the requested institution as @institution" do
        get :show, id: @institution.to_param
        assigns(:institution).should eq(@institution)
      end

    end

    describe "for institutional_admin user" do 
      before do 
        @user.role_ids = [Role.where(name: 'institutional_admin').first.id]
        sign_in @user
      end

      after do
        @user.role_ids = []
      end

      it "responds successfully with an HTTP 200 status code" do
        get :show, id: @institution.to_param
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "renders the index template" do
        get :show, id: @institution.to_param
        expect(response).to render_template("show")
      end

      it "assigns the requested institution as @institution" do
        get :show, id: @institution.to_param
        assigns(:institution).should eq(@institution)
      end
    end

    describe "for institutional_user user" do 
      before do 
        @user.role_ids = [Role.where(name: 'institutional_user').first.id]
        sign_in @user
      end

      after do
        @user.role_ids = []
      end

      it "responds successfully with an HTTP 200 status code" do
        get :show, id: @institution.to_param
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "renders the index template" do
        get :show, id: @institution.to_param
        expect(response).to render_template("show")
      end

      it "assigns the requested institution as @institution" do
        get :show, id: @institution.to_param
        assigns(:institution).should eq(@institution)
      end
    end
  end

  describe "DELETE destroy" do
    describe "with admin user" do
      before do
        @user = FactoryGirl.create(:user, :admin)
        @institution = FactoryGirl.create(:institution)
        sign_in(@user)
      end

      it "should be successful" do
        @name = @institution.name
        delete :destroy, {:id => @institution.to_param}
        response.should redirect_to(institutions_url)
      end
    end
  end

  describe "POST create" do
    describe "with admin user" do
      before do
        @user = FactoryGirl.create(:user, :admin)
        sign_in(@user)
      end

      it "should reject no parameters" do
        expect {
          post :create, {}
        }.to_not change(Institution, :count)
      end

      it 'should accept good parameters' do
        expect {
          post :create, institution: FactoryGirl.attributes_for(:institution)
        }.to change(Institution, :count)
      end
    end
  end

end
