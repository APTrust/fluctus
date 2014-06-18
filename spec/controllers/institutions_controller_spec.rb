require 'spec_helper'

describe InstitutionsController do
  before :all do
    Institution.destroy_all
  end

  let(:admin_user) { FactoryGirl.create(:user, :admin) }
  let(:institutional_user) { FactoryGirl.create(:user, :institutional_user) }
  let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin) }

  describe "GET #index" do
    describe "for admin users" do 
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

      it "assigns all institutions as @institutions" do
        get :index
        assigns(:institutions).should include(admin_user.institution)
      end
    end
  end

  describe "GET #new" do
    describe "for admin users" do 
      before do 
        sign_in admin_user
      end

      it "responds successfully" do
        get :new
        expect(response).to be_success
      end
    end
  end

  describe "GET #show" do
    describe "for admin user" do 
      before do
        sign_in admin_user
      end

      it "responds successfully with an HTTP 200 status code" do
        get :show, id: admin_user.institution
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "renders the index template" do
        get :show, id: admin_user.institution
        expect(response).to render_template("show")
      end

      it "assigns the requested institution as @institution" do
        get :show, id: admin_user.institution
        assigns(:institution).should eq( admin_user.institution)
      end

    end

    describe "for institutional_admin user" do 
      before do 
        sign_in institutional_admin
      end

      it "responds successfully with an HTTP 200 status code" do
        get :show, id: institutional_admin.institution
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "renders the index template" do
        get :show, id: institutional_admin.institution
        expect(response).to render_template("show")
      end

      it "assigns the requested institution as @institution" do
        get :show, id: institutional_admin.institution
        assigns(:institution).should eq(institutional_admin.institution)
      end
    end

    describe "for institutional_user user" do 
      before do 
        sign_in institutional_user
      end
      it "responds successfully with an HTTP 200 status code" do
        get :show, id: institutional_user.institution.to_param
        expect(response).to be_success
        expect(response.status).to eq(200)
      end

      it "renders the index template" do
        get :show, id: institutional_user.institution.to_param
        expect(response).to render_template("show")
      end

      it "assigns the requested institution as @institution" do
        get :show, id: institutional_user.institution.to_param
        assigns(:institution).should eq(institutional_user.institution)
      end
    end
  end

  describe "POST create" do
    describe "with admin user" do
      let (:attributes) { FactoryGirl.attributes_for(:institution) }

      before do
        sign_in admin_user
      end

      it "should reject no parameters" do
        expect {
          post :create, {}
        }.to raise_error ActionController::ParameterMissing
      end

      it 'should accept good parameters' do
        expect {
          post :create, institution: attributes
        }.to change(Institution, :count).by(1)
        response.should redirect_to institution_url(assigns[:institution])
        assigns[:institution].should be_kind_of Institution
      end
    end
    describe "with institutional admin user" do
      let (:attributes) { FactoryGirl.attributes_for(:institution) }
      before do
        sign_in institutional_admin
      end

      it 'should be unauthorized' do
        expect {
          post :create, institution: attributes
        }.to_not change(Institution, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end
  end

end
