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
    @ds.identifier.should_not be_empty
    exp = SecureRandom.uuid
    @ds.identifier = exp
    @ds.identifier.should == [exp]
  end

  it 'should properly set acccess' do
    @ds.access.should_not be_empty
    exp = ['consortia', 'institution', 'restricted'].sample
    @ds.access = exp
    @ds.access.should == [exp]
  end

  it 'should properly set an alternative identifier' do
    exp = 'alt_identifier/123456'
    @ds.alt_identifier = exp
    @ds.alt_identifier.should == [exp]
  end

  it 'should properly set a bag name' do
    exp = '12345678'
    @ds.bag_name = exp
    @ds.bag_name.should == [exp]
  end
end

