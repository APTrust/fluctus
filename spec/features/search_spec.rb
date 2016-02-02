require 'spec_helper'

describe 'Searching' do

  let(:user) { FactoryGirl.create(:user, :institutional_user) }
  it 'should work' do
    login_as user

    visit '/'
    click_link 'Objects'
    expect(page).to have_content "Objects for #{user.institution.title}"
    click_button('search')
  end
end
