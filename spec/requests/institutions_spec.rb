require 'spec_helper'

describe "Institutions" do
  describe "GET /institutions" do
    before do
      @user = FactoryGirl.create(:user, :admin)
    end

    it "works! (now write some real specs)" do
      login_as(@user)
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get institutions_path
      response.status.should be(200)
    end
  end
end
