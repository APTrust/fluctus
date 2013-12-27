require 'spec_helper'

describe IntellectualObjectsController do
  describe "search when some objects are in the repository" do

    before(:all) { IntellectualObject.destroy_all }

    describe "when not signed in" do
      it "should redirect to login" do
        get :index, institution_id: 'apt:123'
        expect(response).to redirect_to root_url
      end
    end


    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_user) }
      let(:another_institution) { FactoryGirl.create(:institution) }
      let!(:obj1) { FactoryGirl.create(:public_intellectual_object,
                                       institution: another_institution) }
      let!(:obj2) { FactoryGirl.create(:institutional_intellectual_object,
                                       institution: user.institution,
                                       title: 'Aberdeen Wanderers Rugby Football Club',
                                       description: 'a Scottish rugby union club. It was founded in Aberdeen in 1928.') }
      let!(:obj3) { FactoryGirl.create(:institutional_intellectual_object,
                                       institution: another_institution) }
      let!(:obj4) { FactoryGirl.create(:private_intellectual_object, 
                                       institution: user.institution,
                                       title: "The 2nd Workers' Cultural Palace Station",
                                       description: 'a station of Line 2 of the Guangzhou Metro.',
                                       identifier: 'jhu.d9abff425d09d5b0') }
      let!(:obj5) { FactoryGirl.create(:private_intellectual_object,
                                       institution: another_institution) }
      before { sign_in user }
        
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
        it "should show the results that I have access to that belong to the institution " do
          get :index, institution_id: another_institution
          expect(response).to be_successful
          expect(assigns(:document_list).size).to eq 1
          assigns(:document_list).each {|doc| expect(doc).to be_kind_of SolrDocument}
          # current user isn't a member of 'another_institution' so we can't see obj3 or obj5.
          expect(assigns(:document_list).map &:id).to match_array [obj1.id]
        end
      end
    end
  end

  describe "view an object" do
    let(:obj1) { FactoryGirl.create(:public_intellectual_object) }
    after { obj1.destroy }

    describe "when not signed in" do
      it "should redirect to login" do
        get :show, id: obj1
        expect(response).to redirect_to root_url
      end
    end


    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_user) }
      before { sign_in user }
        
      it "should show some" do
        get :show, id: obj1
        expect(response).to be_successful
        expect(assigns(:intellectual_object)).to eq obj1
      end
    end
  end

  describe "update an object" do
    after { obj1.destroy }

    describe "when not signed in" do
      let(:obj1) { FactoryGirl.create(:public_intellectual_object) }
      it "should redirect to login" do
        patch :update, id: obj1, intellectual_object: {title: 'Foo' }
        expect(response).to redirect_to root_url
      end
    end


    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user, :institutional_admin) }
      let(:obj1) { FactoryGirl.create(:public_intellectual_object, institution_id: user.institution_pid) }
      before { sign_in user }
        
      it "should update fields" do
        patch :update, id: obj1, intellectual_object: {title: 'Foo'}
        expect(response).to redirect_to intellectual_object_path(obj1)
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end

      it "should update via json" do
        patch :update, id: obj1, intellectual_object: {title: 'Foo'}, format: 'json'
        expect(response).to be_successful
        expect(assigns(:intellectual_object).title).to eq 'Foo'
      end
    end

  end
end
