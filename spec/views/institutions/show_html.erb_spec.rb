require 'spec_helper'

describe 'institutions/show.html.erb' do
  let(:inst) { FactoryGirl.create(:institution) }
  before { assign(:institution, inst) }

  it 'displays a link to recently changed objects' do
    render
    rendered.should have_link('Objects', href: institution_intellectual_objects_path(inst, sort: 'system_modified_dtsi desc'))
  end
end
