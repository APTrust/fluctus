require 'spec_helper'

describe "Editing an IntellectualObject" do
  
  let(:admin_user) { FactoryGirl.create(:user, :admin) }
  let!(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
  it "should work" do
    login_as admin_user

    visit '/'
    fill_in 'q', with: intellectual_object.title
    click_button 'Search'
    click_link 'Edit'
    fill_in 'Description', with: "I updated it"
    click_button "Save"
    expect(page).to have_content 'Object was successfully updated.'
  end
end