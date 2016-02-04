require 'spec_helper'

describe 'Users' do

  after do
    Institution.destroy_all
  end

  describe 'DELETE users', :type => :feature do
    before do
      @institution = FactoryGirl.create(:institution)
      @user = FactoryGirl.create(:user, :institutional_admin, institution_pid: @institution.id)
      @user2 = FactoryGirl.create(:user, institution_pid: @institution.id)
    end

    it 'should provide message after delete with name of deleted instituion' do
      login_as(@user)
      visit('/users')
      expect {
        within(:xpath, "//tr[@id='#{@user2.id}']") do
          click_link 'Delete'
        end
      }.to change(User, :count).by(-1)
      page.should have_content "#{@user2.name} was deleted."
    end
  end
end
