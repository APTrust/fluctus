require 'spec_helper'

describe "institutions/show" do
  before(:each) do
    @institution = assign(:institution, stub_model(Institution,
      :name => "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
  end
end
