require 'spec_helper'

describe "institutions/edit" do
  before(:each) do
    @institution = assign(:institution, stub_model(Institution,
      :name => "MyString"
    ))
  end

  it "renders the edit institution form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", institution_path(@institution), "post" do
      assert_select "input#institution_name[name=?]", "institution[name]"
    end
  end
end
