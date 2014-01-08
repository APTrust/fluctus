require 'spec_helper'

describe CatalogController do

  before { sign_in user }

  let(:active_query) { "_query_:\"{!raw f=object_state_ssi}A\"" }
  let(:object_type_query) { "_query_:\"{!raw f=has_model_ssim}info:fedora/afmodel:IntellectualObject\"" }
  describe "with an admin" do
    let(:user) { FactoryGirl.create(:user, :admin) } 
    it "should query for active intellectual objects" do 
      expect(subject.solr_search_params()[:fq]).to eq [object_type_query, active_query]
    end
  end

  describe "with an institutional admin" do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) } 
    let(:inst_pid) { user.institution_pid.sub(":", '_') }
    it "should add a fq for the user's institution" do 
      expect(subject.solr_search_params()[:fq].first).to include("edit_access_group_ssim:Admin_At_#{inst_pid}")
    end

    describe "filtering active objects" do
      it "should filter" do
        expect(subject.solr_search_params()[:fq]).to include(object_type_query, active_query)
      end
      it "should not filter if 'show_all' is set" do
        controller.params = {show_all: 'true'}
        expect(subject.solr_search_params()[:fq]).to_not include(active_query)
      end
    end
  end
end
