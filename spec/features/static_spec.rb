require 'spec_helper'

describe 'Static' do
  let(:user) { FactoryGirl.create(:user, :institutional_user) }
  it 'should always route to the static page' do
    login_as user

    visit '/'
    click_button('search')
    expect(page).to have_content 'These servers are now running APTrust 2.0'
    click_link 'View Profile'
    expect(page).to have_content 'These servers are now running APTrust 2.0'
    visit '/institutions'
    expect(page).to have_content 'These servers are now running APTrust 2.0'
  end
end