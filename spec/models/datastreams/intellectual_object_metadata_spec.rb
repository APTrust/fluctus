# Generated via
#  `rails generate active_fedora::model IntellectualObject`
require 'spec_helper'

describe IntellectualObjectMetadata do

  before do
    @gf = FactoryGirl.create(:intellectual_object)
    @ds = @gf.descMetadata
  end

  after do
    @gf.destroy
  end

  it 'should properly set a title' do
    @ds.title.should_not be_empty
    @ds.title = 'War and Peace'
    @ds.title.should == ['War and Peace']
    @ds.title << "this is another title"
    @ds.title.count.should == 2
  end

  it 'should properly set a description' do
    @ds.description.should_not be_empty
    exp = Faker::Lorem.paragraph
    @ds.description = exp
    @ds.description.should == [exp]
  end

  it 'should properly set an identifier' do
    @ds.intellectualobject_identifier.should_not be_empty
    exp = SecureRandom.uuid
    @ds.intellectualobject_identifier = exp
    @ds.intellectualobject_identifier.should == [exp]
  end

  it 'should properly set rights' do
    @ds.rights.should_not be_empty
    exp = ['consortial', 'institution', 'restricted'].sample
    @ds.rights = exp
    @ds.rights.should == [exp]
  end
end

