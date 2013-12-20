require 'spec_helper'

describe UsersController do
  describe "An APTrust Administrator" do
    let(:admin_user) { FactoryGirl.create(:user, :admin) }
    let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}

    before { sign_in admin_user }

    it 'can get a list of users' do
      get :new
      response.should be_successful
      expect(assigns[:user]).to be_kind_of User
    end

    it 'can show an Institutional Administrators' do
      get :show, id: institutional_admin
      response.should be_successful
      expect(assigns[:user]).to eq institutional_admin 
    end

    it 'can load a form to create a new user' do
      get :new
      response.should be_successful
      expect(assigns[:user]).to be_kind_of User
    end

    describe "can create Institutional Administrators" do
      let(:institutional_admin_role_id) { Role.where(name: 'institutional_admin').first.id}
      let(:attributes) { FactoryGirl.attributes_for(:user, :role_ids => [institutional_admin_role_id]) }

      it "unless no parameters are passed" do
        expect {
          post :create, {}
        }.to_not change(User, :count)
      end

      it 'when the parameters are valid' do
        expect {
          post :create, user: attributes
        }.to change(User, :count).by(1)
        response.should redirect_to user_url(assigns[:user])
        expect(assigns[:user]).to be_institutional_admin
      end
    end

    it 'can edit Institutional Administrators' do
      get :edit, id: institutional_admin
      response.should be_successful
      expect(assigns[:user]).to eq institutional_admin 
    end

    describe "can update Institutional Administrators" do
      let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}

      it 'when the parameters are valid' do
        patch :update, id: institutional_admin, user: {name: 'Frankie'}
        response.should redirect_to user_url(institutional_admin)
        expect(flash[:notice]).to eq 'User was successfully updated.'
        expect(assigns[:user].name).to eq 'Frankie'
      end
      it 'when the parameters are invalid' do
        patch :update, id: institutional_admin, user: {phone_number: 'f121'}
        response.should be_successful
        expect(assigns[:user].errors.include?(:phone_number)).to be_true
      end
    end


  end
end
