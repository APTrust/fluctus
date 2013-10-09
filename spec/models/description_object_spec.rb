require 'spec_helper'

describe DescriptionObject do
  # let(:i) { FactoryGirl.create(:institution) }
  # let(:desc) { FactoryGirl.create(:description_object, institution: i) }
  # let(:bag) { FactoryGirl.create(:bag, description_object: desc)}

  before do
    @i = FactoryGirl.create(:institution)
    @desc = FactoryGirl.create(:description_object, institution: @i)
    @bag = FactoryGirl.create(:bag, description_object: @desc)
    @desc.reload # ensure DescriptionObject bags are available
  end

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:institution) }

  it "should have one bag associated" do 
    @desc.bags.count.should == 1
    @desc.bags.should == [@bag]
  end

  it 'should retun a proper solr_doc' do
    @desc.to_solr['institution_name_tesim'].should == @i.name
    @desc.to_solr['desc_metadata__title_tesim'].should == [@desc.title]
    @desc.to_solr['original_pid_tesim'].should == @bag.parse_pid
  end

  it 'should throw an error if no insitution is assigned.' do
    @desc.institution = nil
    lambda {@desc.save!}.should raise_error
  end
end