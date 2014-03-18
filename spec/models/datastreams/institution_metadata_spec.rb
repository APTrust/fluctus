require 'spec_helper'

describe InstitutionMetadata do
  before(:all) do 
    @i = Institution.new(pid: 'test:1234')
    @datastream = InstitutionMetadata.new(@i)
    @datastream.name = "Test"
    @datastream.brief_name = "tst"
    @datastream.institution_identifier = "test.edu"
  end

  it 'should retain properties' do
    @datastream.name.first.should == "Test"
    @datastream.brief_name.first.should == "tst"
    @datastream.institution_identifier.first.should == "test.edu"
  end

end