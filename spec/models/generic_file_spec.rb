require 'spec_helper'

describe GenericFile do

  subject { FactoryGirl.create(:generic_file) }

  it 'should have a descMetadata datastream' do
    subject.descMetadata.should be_kind_of GenericFileMetadata
  end

  it 'should have a premisEvents datastream' do
    subject.premisEvents.should be_kind_of Datastream::PremisEventDatastream
  end

end