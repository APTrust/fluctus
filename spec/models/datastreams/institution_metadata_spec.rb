require 'spec_helper'

describe Datastream::InstitutionMetadata do 
  before(:all) do 
    @i = Institution.new(pid: 'test:1234')
    @datastream = Datastream::InstitutionMetadata.new(@i)
    @datastream.name = "Test"
  end

  it 'should retain properties' do
    @datastream.name.should == ["Test"]
  end

  it 'should serialize' do 
    @datastream.serialize.should be_equivalent_to "<info:fedora/test:1234> <http://purl.org/dc/terms/title> \"Test\" .\n"
  end
end