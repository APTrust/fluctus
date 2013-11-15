# Generated via
#  `rails generate active_fedora::model IntellectualObject`
require 'spec_helper'
require 'active_fedora/test_support'

describe IntellectualObject do

  before do
    @i = FactoryGirl.create(:intellectual_object)
  end

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:institution) }

  it 'should have a descMetadata datastream' do
    subject.descMetadata.should be_kind_of IntellectualObjectMetadata
  end

end
