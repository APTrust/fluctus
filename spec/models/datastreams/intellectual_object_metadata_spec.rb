# Generated via
#  `rails generate active_fedora::model IntellectualObject`
require 'spec_helper'

describe IntellectualObjectMetadata do

  before do
    @item = FactoryGirl.create(:intellectual_object)
    @ds = @item.descMetadata
  end

  after do
    @item.destroy
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
end

