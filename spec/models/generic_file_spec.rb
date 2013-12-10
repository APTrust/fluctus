require 'spec_helper'

describe GenericFile do

  subject { FactoryGirl.create(:generic_file) }

  it 'should have a descMetadata datastream' do
    subject.descMetadata.should be_kind_of GenericFileMetadata
  end

  it 'should have a premisEvents datastream' do
    subject.premisEvents.should be_kind_of PremisEventsMetadata
  end

  it 'should validate the presence of a uri' do
    subject.uri = nil
    subject.should_not be_valid
  end

  it 'should validate presence of size' do
    subject.size = nil
    subject.should_not be_valid
  end

  it 'should validate presence of created' do
    subject.created = nil
    subject.should_not be_valid
  end

  it 'should validate presence of modified' do
    subject.modified = nil
    subject.should_not be_valid
  end

  it 'should validate presence of format' do
    subject.modified = nil
    subject.should_not be_valid
  end

  it 'should validate presence of a checksum' do
    subject.checksum = nil
    subject.should_not be_valid
  end

end