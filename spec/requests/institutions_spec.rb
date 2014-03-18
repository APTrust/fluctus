require 'spec_helper'

describe "Institutions" do
  describe "DELETE institutions", :type => :feature do
    before do
      @user = FactoryGirl.create(:user, :admin)
      @institution = FactoryGirl.create(:institution)
    end

    it "should provide message after delete with name of deleted instituion" do
      login_as(@user)
      visit('/institutions')
      expect {
        within(:xpath, "//tr[@id='#{@institution.institution_identifier}']") do
          click_link "Delete"
        end
      }.to change(Institution, :count).by(-1)
      page.should have_content "#{@institution.name} was successfully destroyed."
    end
  end
end
