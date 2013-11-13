require 'spec_helper'

describe Datastream::InstitutionMetadata do 
  before(:all) do 
    @i = Institution.new(pid: 'test:1234')
    @datastream = Datastream::InstitutionMetadata.new(@i)
    @datastream.name = "Test"
    @datastream.brief_name = "tst"
  end

  it 'should retain properties' do
    @datastream.name.first.should == "Test"
    @datastream.brief_name.first.should == "tst"
  end

end