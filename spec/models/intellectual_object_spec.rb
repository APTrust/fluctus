# Generated via
#  `rails generate active_fedora::model IntellectualObject`
require 'spec_helper'
require 'active_fedora/test_support'

describe IntellectualObject do

  before do
    subject = FactoryGirl.create(:intellectual_object)
  end

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:institution) }

  it 'should have a descMetadata datastream' do
    subject.descMetadata.should be_kind_of IntellectualObjectMetadata
  end

  it 'should properly set a title' do
    subject.title = 'War and Peace'
    subject.title.should == 'War and Peace'
  end

  it 'should properly set a description' do
    exp = Faker::Lorem.paragraph
    subject.description = exp
    subject.description.should == [exp]
  end

  it 'should properly set an identifier' do
    exp = SecureRandom.uuid
    subject.identifier = exp
    subject.identifier.should == [exp]
  end

end
