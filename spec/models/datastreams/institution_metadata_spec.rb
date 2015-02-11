require 'spec_helper'

describe InstitutionMetadata do
  before(:all) do 
    @i = Institution.new(pid: 'test:1234')
    @datastream = InstitutionMetadata.new(@i)
    @datastream.title = "Test"
    @datastream.brief_name = "tst"
    @datastream.identifier = "test.org"
  end

  it 'should retain properties' do
    @datastream.title.first.should == "Test"
    @datastream.brief_name.first.should == "tst"
    @datastream.identifier.first.should == "test.org"
  end

end