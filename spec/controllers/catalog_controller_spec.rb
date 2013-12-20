require 'spec_helper'

describe CatalogController do

  it "should NOT add a fq on an admin user's institution" do 
    @user = FactoryGirl.create(:user, :admin)
    sign_in @user
    subject.solr_search_params({})[:fq].should_not include("+is_part_of_ssim:\"info:fedora/#{@user.institution.pid}\"")
  end

end