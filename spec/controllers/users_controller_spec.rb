require 'spec_helper'

describe UsersController do
  describe "An APTrust Administrator" do
    let(:admin_user) { FactoryGirl.create(:user, :admin) }
    let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}

    before { sign_in admin_user }

    describe "who gets a list of users" do
      let!(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}
      let!(:institutional_user) { FactoryGirl.create(:user, :institutional_user)}
      it 'should see all the users' do
        get :index
        response.should be_successful
        expect(assigns[:users]).to include(admin_user, institutional_admin, institutional_user) 
      end
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


  describe "An Institutional Administrator" do
    let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}

    before { sign_in institutional_admin }

    describe "who gets a list of users" do
      let!(:user_at_institution) {  FactoryGirl.create(:user, :institutional_user, institution_pid: institutional_admin.institution_pid) }
      let!(:user_of_different_institution) {  FactoryGirl.create(:user, :institutional_user) }
      it 'can only see users in their institution' do
        get :index
        response.should be_successful
        expect(assigns[:users]).to include user_at_institution
        expect(assigns[:users]).to_not include user_of_different_institution
      end
    end

    describe "show an Institutinal User" do 
      describe "at my institution" do
        let(:user_at_institution) {  FactoryGirl.create(:user, :institutional_user, institution_pid: institutional_admin.institution_pid) }
        it 'can show the Institutional Users for my institution' do
          get :show, id: user_at_institution
          response.should be_successful
          expect(assigns[:user]).to eq user_at_institution 
        end
      end

      describe "at a different institution" do
        let(:user_of_different_institution) {  FactoryGirl.create(:user, :institutional_user) }
        it "can't show" do
          get :show, id: user_of_different_institution
          response.should redirect_to root_url
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end
    end

    it 'can load a form to create a new user' do
      get :new
      response.should be_successful
      expect(assigns[:user]).to be_kind_of User
    end

    describe "creating Institutional User" do
      let(:institutional_admin_role_id) { Role.where(name: 'institutional_admin').first.id}

      describe "at another institution" do
        let(:attributes) { FactoryGirl.attributes_for(:user) }
        it "shouldn't work" do
          expect {
            post :create, user: attributes
          }.not_to change(User, :count)
          response.should redirect_to root_path
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end

      describe "at my institution" do
        describe "with institutional_user role" do
          let(:institutional_user_role_id) { Role.where(name: 'institutional_user').first.id}
          let(:attributes) { FactoryGirl.attributes_for(:user, :institution_pid=>institutional_admin.institution_pid, :role_ids => [institutional_user_role_id]) }
          it 'should be successful' do
            expect {
              post :create, user: attributes
            }.to change(User, :count).by(1)
            response.should redirect_to user_url(assigns[:user])
            expect(assigns[:user]).to be_institutional_user
          end
        end
        describe "with institutional_admin role" do
          let(:attributes) { FactoryGirl.attributes_for(:user, institution_pid: institutional_admin.institution_pid, role_ids: [institutional_admin_role_id]) }
          it 'should show an error' do
            expect {
              post :create, user: attributes
            }.to_not change(User, :count)
            response.should be_redirect
            expect(flash[:alert]).to eq "You are not authorized to access this page."
          end
        end
      end
    end

    describe "editing Institutional User" do
      describe 'from my institution' do
        let(:user_at_institution) {  FactoryGirl.create(:user, :institutional_user, institution_pid: institutional_admin.institution_pid) }
        it "should be successful" do
          get :edit, id: user_at_institution
          response.should be_successful
          expect(assigns[:user]).to eq user_at_institution 
        end
      end
      describe 'from another institution' do
        let(:user_of_different_institution) {  FactoryGirl.create(:user, :institutional_user) }
        it "should show an error" do
          get :edit, id: user_of_different_institution
          response.should be_redirect
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end
    end

    describe "can update Institutional users" do
      let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin)}
      describe 'from my institution' do
        let(:user_at_institution) {  FactoryGirl.create(:user, :institutional_user, institution_pid: institutional_admin.institution_pid) }
        it "should be successful" do
          patch :update, id: user_at_institution, user: {name: 'Frankie'}
          response.should redirect_to user_url(user_at_institution)
          expect(assigns[:user]).to eq user_at_institution 
        end
      end
      describe 'from another institution' do
        let(:user_of_different_institution) {  FactoryGirl.create(:user, :institutional_user) }
        it "should show an error message" do
          patch :update, id: user_of_different_institution, user: {name: 'Frankie'}
          response.should be_redirect
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end
    end

  end
end
