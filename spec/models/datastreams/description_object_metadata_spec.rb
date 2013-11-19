require 'spec_helper'

describe DescriptionObjectMetadata do
  before(:all) do 
    @desc = DescriptionObject.new(pid: 'test:1234')
    @datastream = DescriptionObjectMetadata.new(@desc)
    @datastream.title = "Test"
  end

  it 'should retain properties' do
    @datastream.title.should == ["Test"]
  end

  it 'should serialize' do 
    @datastream.serialize.should be_equivalent_to "<info:fedora/test:1234> <http://purl.org/dc/terms/title> \"Test\" .\n"
  end
end