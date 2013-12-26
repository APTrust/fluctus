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
      let!(:obj1) { FactoryGirl.create(:public_intellectual_object, institution: another_institution) }
      let!(:obj2) { FactoryGirl.create(:institutional_intellectual_object, institution: user.institution) }
      let!(:obj3) { FactoryGirl.create(:institutional_intellectual_object, institution: another_institution) }
      let!(:obj4) { FactoryGirl.create(:private_intellectual_object, institution: user.institution) }
      let!(:obj5) { FactoryGirl.create(:private_intellectual_object, institution: another_institution) }
      before { sign_in user }
        
      describe "and viewing my institution" do
        it "should show the results that I have access to that belong to the institution" do
          get :index, institution_id: user.institution
          expect(response).to be_successful
          expect(assigns(:document_list).size).to eq 2
          assigns(:document_list).each {|doc| expect(doc).to be_kind_of SolrDocument}
          expect(assigns(:document_list).map &:id).to match_array [obj2.id, obj4.id]
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
end
