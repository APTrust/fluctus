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
        @description_object = FactoryGirl.create(:description_object, institution: @institution)
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

      it "assigns the requested institution description_objects as @description_objects" do
        get :show, id: @institution.to_param
        assigns(:descripion_objects).should eq(@description_objects)
      end

      it "should assign no more than 50 description objects to @description_objects" do
        51.times { FactoryGirl.create(:description_object, institution: @institution) }
        get :show, id: @institution.to_param
        expect(assigns(:description_objects).count).to eq(50)
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

  # describe "GET new" do
  #   it "assigns a new institution as @institution" do
  #     get :new, {}, valid_session
  #     assigns(:institution).should be_a_new(Institution)
  #   end
  # end

  # describe "GET edit" do
  #   it "assigns the requested institution as @institution" do
  #     institution = Institution.create! valid_attributes
  #     get :edit, {:id => institution.to_param}, valid_session
  #     assigns(:institution).should eq(institution)
  #   end
  # end

  # describe "POST create" do
  #   describe "with valid params" do
  #     it "creates a new Institution" do
  #       expect {
  #         post :create, {:institution => valid_attributes}, valid_session
  #       }.to change(Institution, :count).by(1)
  #     end

  #     it "assigns a newly created institution as @institution" do
  #       post :create, {:institution => valid_attributes}, valid_session
  #       assigns(:institution).should be_a(Institution)
  #       assigns(:institution).should be_persisted
  #     end

  #     it "redirects to the created institution" do
  #       post :create, {:institution => valid_attributes}, valid_session
  #       response.should redirect_to(Institution.last)
  #     end
  #   end

  #   describe "with invalid params" do
  #     it "assigns a newly created but unsaved institution as @institution" do
  #       # Trigger the behavior that occurs when invalid params are submitted
  #       Institution.any_instance.stub(:save).and_return(false)
  #       post :create, {:institution => { "name" => "invalid value" }}, valid_session
  #       assigns(:institution).should be_a_new(Institution)
  #     end

  #     it "re-renders the 'new' template" do
  #       # Trigger the behavior that occurs when invalid params are submitted
  #       Institution.any_instance.stub(:save).and_return(false)
  #       post :create, {:institution => { "name" => "invalid value" }}, valid_session
  #       response.should render_template("new")
  #     end
  #   end
  # end

  # describe "PUT update" do
  #   describe "with valid params" do
  #     it "updates the requested institution" do
  #       institution = Institution.create! valid_attributes
  #       # Assuming there are no other institutions in the database, this
  #       # specifies that the Institution created on the previous line
  #       # receives the :update_attributes message with whatever params are
  #       # submitted in the request.
  #       Institution.any_instance.should_receive(:update).with({ "name" => "MyString" })
  #       put :update, {:id => institution.to_param, :institution => { "name" => "MyString" }}, valid_session
  #     end

  #     it "assigns the requested institution as @institution" do
  #       institution = Institution.create! valid_attributes
  #       put :update, {:id => institution.to_param, :institution => valid_attributes}, valid_session
  #       assigns(:institution).should eq(institution)
  #     end

  #     it "redirects to the institution" do
  #       institution = Institution.create! valid_attributes
  #       put :update, {:id => institution.to_param, :institution => valid_attributes}, valid_session
  #       response.should redirect_to(institution)
  #     end
  #   end

  #   describe "with invalid params" do
  #     it "assigns the institution as @institution" do
  #       institution = Institution.create! valid_attributes
  #       # Trigger the behavior that occurs when invalid params are submitted
  #       Institution.any_instance.stub(:save).and_return(false)
  #       put :update, {:id => institution.to_param, :institution => { "name" => "invalid value" }}, valid_session
  #       assigns(:institution).should eq(institution)
  #     end

  #     it "re-renders the 'edit' template" do
  #       institution = Institution.create! valid_attributes
  #       # Trigger the behavior that occurs when invalid params are submitted
  #       Institution.any_instance.stub(:save).and_return(false)
  #       put :update, {:id => institution.to_param, :institution => { "name" => "invalid value" }}, valid_session
  #       response.should render_template("edit")
  #     end
  #   end
  # end

  # describe "DELETE destroy" do
  #   it "destroys the requested institution" do
  #     institution = Institution.create! valid_attributes
  #     expect {
  #       delete :destroy, {:id => institution.to_param}, valid_session
  #     }.to change(Institution, :count).by(-1)
  #   end

  #   it "redirects to the institutions list" do
  #     institution = Institution.create! valid_attributes
  #     delete :destroy, {:id => institution.to_param}, valid_session
  #     response.should redirect_to(institutions_url)
  #   end
  # end

end
