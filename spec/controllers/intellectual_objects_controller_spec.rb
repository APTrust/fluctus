require 'spec_helper'

describe IntellectualObjectsController do
  describe "search" do

    before(:all) do
      IntellectualObject.destroy_all
      Institution.destroy_all
    end

    describe "when not signed in" do
      it "should redirect to login" do
        get :index, institution_id: 'apt:123'
        expect(response).to redirect_to root_url + "users/sign_in"
      end
    end


    describe "when some objects are in the repository and signed in" do
      let(:another_institution) { FactoryGirl.create(:institution) }

      let!(:obj1) { FactoryGirl.create(:consortial_intellectual_object,
                                       institution: another_institution) }
      let!(:obj2) { FactoryGirl.create(:institutional_intellectual_object,
                                       institution: user.institution,
                                       title: 'Aberdeen Wanderers Rugby Football Club',
                                       description: 'a Scottish rugby union club. It was founded in Aberdeen in 1928.') }
      let!(:obj3) { FactoryGirl.create(:institutional_intellectual_object,
                                       institution: another_institution) }
      let!(:obj4) { FactoryGirl.create(:restricted_intellectual_object,
                                       institution: user.institution,
                                       title: "The 2nd Workers' Cultural Palace Station",
                                       description: 'a station of Line 2 of the Guangzhou Metro.',
                                       identifier: 'jhu.d9abff425d09d5b0') }
      let!(:obj5) { FactoryGirl.create(:restricted_intellectual_object,
                                       institution: another_institution) }

      before { sign_in user }
      describe "as an institutional user" do
        let(:user) { FactoryGirl.create(:user, :institutional_user) }
        describe "and viewing my institution" do
          it "should show the results that I have access to that belong to the institution" do
            get :index, institution_id: user.institution
            expect(response).to be_successful
            expect(assigns(:document_list).size).to eq 2
            assigns(:document_list).each {|doc| expect(doc).to be_kind_of SolrDocument}
            expect(assigns(:document_list).map &:id).to match_array [obj2.id, obj4.id]
          end

          it "should match a partial search on title" do
            get :index, institution_id: user.institution, q: 'Rugby'
            expect(response).to be_successful
            expect(assigns(:document_list).map &:id).to match_array [obj2.id]
          end
          it "should match a partial search on description" do
            get :index, institution_id: user.institution, q: 'Guangzhou'
            expect(response).to be_successful
            expect(assigns(:document_list).map &:id).to match_array [obj4.id]
          end
          it "should match an exact search on identifier" do
            get :index, institution_id: user.institution, q: 'jhu.d9abff425d09d5b0'
            expect(response).to be_successful
            expect(assigns(:document_list).map &:id).to match_array [obj4.id]
          end
        end
        describe "and viewing another institution" do
          it "should redirect" do
            get :index, institution_id: another_institution
            expect(response).to redirect_to root_url
            expect(flash[:alert]).to eq "You are not authorized to access this page."
          end
        end
      end

      describe "when signed in as an admin" do
        let(:user) { FactoryGirl.create(:user, :admin) }
        describe "and viewing another institution" do
          it "should show the results that I have access to that belong to the institution " do
            get :index, institution_id: another_institution
            expect(response).to be_successful
            expect(assigns(:document_list).size).to eq 3
            assigns(:document_list).each {|doc| expect(doc).to be_kind_of SolrDocument}
            expect(assigns(:document_list).map &:id).to match_array [obj1.id, obj3.id, obj5.id]
          end
        end
      end
    end
  end

  describe "view an object" do
    let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
    after { obj1.destroy }

    describe "when not signed in" do
      it "should redirect to login" do
        get :show, id: obj1
        expect(response).to redirect_to root_url + "users/sign_in"
      end
    end

    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_user) }
      before { sign_in user }

      it "should show the object" do
        get :show, id: obj1
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

      it "should show the object by identifier for API users" do
        get :show, identifier: obj1.identifier, use_route: 'object_by_identifier'
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end

    end
  end

  describe "edit an object" do
    after { obj1.destroy }

    describe "when not signed in" do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      it "should redirect to login" do
        get :edit, id: obj1
        expect(response).to redirect_to root_url + "users/sign_in"
      end
    end

    describe "when signed in" do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution: user.institution) }
      describe "as an institutional_user" do
        let(:user) { FactoryGirl.create(:user, :institutional_user) }
        before { sign_in user }

        it "should be unauthorized" do
          get :edit, id: obj1
          expect(response).to redirect_to root_url
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end
      describe "as an institutional_admin" do
        let(:user) { FactoryGirl.create(:user, :institutional_admin) }
        before { sign_in user }

        it "should show the object" do
          get :edit, id: obj1
          expect(response).to be_successful
          expect(assigns(:intellectual_object)).to eq obj1
        end
      end
    end
  end

  describe "update an object" do
    after { obj1.destroy }

    describe "when not signed in" do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      it "should redirect to login" do
        patch :update, id: obj1, intellectual_object: {title: 'Foo' }
        expect(response).to redirect_to root_url + "users/sign_in"
      end
    end


    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution_id: user.institution_pid) }
      before { sign_in user }

      it "should update the search counter" do
        patch :update, id: obj1, counter: '5'
        expect(response).to redirect_to intellectual_object_path(obj1)
        expect(session[:search][:counter]).to eq '5'
      end

      it "should update fields" do
        patch :update, id: obj1, intellectual_object: {title: 'Foo'}
        expect(response).to redirect_to intellectual_object_path(obj1)
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end

      it "should update fields when called with identifier (API)" do
        patch :update, identifier: obj1.identifier, intellectual_object: {title: 'Foo'}, use_route: 'object_update_by_identifier'
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end

      it "should update via json" do
        patch :update, id: obj1, intellectual_object: {title: 'Foo'}, format: 'json'
        expect(response).to be_successful
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end
    end
  end

  describe "create an object" do

    describe "when not signed in" do
      it "should redirect to login" do
        post :create, institution_id: FactoryGirl.create(:institution), intellectual_object: {title: 'Foo' }
        expect(response).to redirect_to root_url + "users/sign_in"
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
      end
    end

    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      before { sign_in user }

      it "should only allow assigning institutions you have access to" do
        post :create, institution_id: FactoryGirl.create(:institution), intellectual_object: {title: 'Foo'}, format: 'json'
        expect(response.code).to eq "403" # forbidden
        expect(JSON.parse(response.body)).to eq({"status"=>"error","message"=>"You are not authorized to access this page."})
       end

      it "should show errors" do
        post :create, institution_id: user.institution_pid, intellectual_object: {title: 'Foo'}, format: 'json'
        expect(response.code).to eq '422' #Unprocessable Entity
        expect(JSON.parse(response.body)).to eq({"identifier" => ["can't be blank"],"access" => ["can't be blank"]})
      end

      it "should update fields" do
        post :create, institution_id: user.institution_pid, intellectual_object: {title: 'Foo', identifier: '123', access: 'restricted'}, format: 'json'
        expect(response.code).to eq '201'
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end

      it "should use the institution parameter in the URL, not from the json" do
        expect {
          post :create, institution_id: user.institution_pid, intellectual_object: {title: 'Foo', institution_id: 'test:123', identifier: '123', access: 'restricted'}, format: 'json'
          expect(response.code).to eq '201'
          expect(assigns(:intellectual_object).title).to eq 'Foo'
          expect(assigns(:intellectual_object).institution_id).to eq user.institution_pid
        }.to change(IntellectualObject, :count).by(1)
      end
    end
  end

  describe "destroy an object" do
    describe "when not signed in" do
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object) }
      after { obj1.destroy }
      it "should redirect to login" do
        delete :destroy, id: obj1
        expect(response).to redirect_to root_url + "users/sign_in"
      end
    end

    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      let(:obj1) { FactoryGirl.create(:consortial_intellectual_object, institution_id: user.institution_pid) }
      before { sign_in user }

      it "should update via json" do
        delete :destroy, id: obj1, format: 'json'
        expect(response.code).to eq '204'
        expect(assigns(:intellectual_object).state).to eq 'D'
      end

      it "should update via html" do
        delete :destroy, id: obj1
        expect(response).to redirect_to root_path
        expect(flash[:notice]).to eq "Delete job has been queued for object: #{obj1.title}"
        expect(assigns(:intellectual_object).state).to eq 'D'
      end
    end
  end
end
