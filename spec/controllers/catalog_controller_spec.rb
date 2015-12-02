require 'spec_helper'

describe CatalogController do

  before { sign_in user }

  let(:active_query) { "_query_:\"{!raw f=object_state_ssi}A\"" }
  let(:object_type_query) { "_query_:\"{!raw f=has_model_ssim}info:fedora/afmodel:IntellectualObject\"" }
  describe 'with an admin' do
    let(:user) { FactoryGirl.create(:user, :admin) } 
    it 'should query for active intellectual objects' do
      expect(subject.solr_search_params()[:fq]).to eq [object_type_query, active_query]
    end
  end

  describe 'with an institutional admin' do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) } 
    let(:inst_pid) { user.institution_pid.sub(':', '_') }
    it "should add a fq for the user's institution" do 
      expect(subject.solr_search_params()[:fq].first).to include("edit_access_group_ssim:Admin_At_#{inst_pid}")
    end

    describe 'filtering by objects state' do
      let(:deleted_query) { "_query_:\"{!raw f=object_state_ssi}D\"" }
      it 'should filter' do
        expect(subject.solr_search_params()[:fq]).to include(object_type_query, active_query)
        expect(subject.solr_search_params()[:fq]).to_not include(deleted_query)
      end
      it "should not filter if 'show' is 'all'" do
        controller.params = {show: 'all'}
        expect(subject.solr_search_params()[:fq]).to_not include(active_query)
        expect(subject.solr_search_params()[:fq]).to_not include(deleted_query)
      end
      it "should only have deleted if 'show' is 'deleted'" do
        controller.params = {show: 'deleted'}
        expect(subject.solr_search_params()[:fq]).to_not include(active_query)
        expect(subject.solr_search_params()[:fq]).to include(deleted_query)
      end
    end
  end
end
