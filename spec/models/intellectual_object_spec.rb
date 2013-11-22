# Generated via
#  `rails generate active_fedora::model IntellectualObject`
require 'spec_helper'
require 'active_fedora/test_support'

describe IntellectualObject do

  let(:subject) { FactoryGirl.create(:intellectual_object) }

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:institution) }
  it { should validate_presence_of(:rights)}

  it 'should have a descMetadata datastream' do
    subject.descMetadata.should be_kind_of IntellectualObjectMetadata
  end

  it 'should properly set a title' do
    subject.title = 'War and Peace'
    subject.title.should == 'War and Peace'
  end

  it 'should properly set rights' do
    subject.rights = 'public'
    subject.rights.should == 'public'
  end

  it 'must be one of the standard rights' do
    subject.rights = 'error'
    subject.should_not be_valid
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

  it 'must check for generic_files before destory' do
    item = FactoryGirl.create(:generic_file, intellectual_object: subject)
    subject.destroy.should be_false
    item.destroy
  end

end
