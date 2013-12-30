require 'spec_helper'

describe "Adding a new user" do
  
  let(:admin_user) { FactoryGirl.create(:user, :admin) }
  it "should work" do
    login_as admin_user

    visit '/'
    click_link 'New User'
    fill_in 'Email', with: "sonja@example.com"
    fill_in 'Phone number', with: "712-858-2392"
    select "APTrust", from: "Institution"
    check 'Institutional Admin'
    click_button "Submit"
    expect(page).to have_content 'User was successfully created.'
  end
end

