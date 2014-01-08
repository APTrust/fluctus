require 'spec_helper'

describe CatalogController do

  before { sign_in user }

  describe "with an admin" do
    let(:user) { FactoryGirl.create(:user, :admin) } 
    it "should NOT add a fq of the institution" do 
      subject.solr_search_params({})[:fq].should be_nil
    end
  end

  describe "with an institutional admin" do
    let(:user) { FactoryGirl.create(:user, :institutional_admin) } 
    it "should add a fq for the user's institution" do 
      subject.solr_search_params({})[:fq].should_not include("+is_part_of_ssim:\"info:fedora/#{user.institution.pid}\"")
    end
  end

end
