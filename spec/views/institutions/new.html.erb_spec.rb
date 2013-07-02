require 'spec_helper'

describe "institutions/new" do
  before(:each) do
    assign(:institution, stub_model(Institution,
      :name => "MyString"
    ).as_new_record)
  end

  it "renders new institution form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", institutions_path, "post" do
      assert_select "input#institution_name[name=?]", "institution[name]"
    end
  end
end
