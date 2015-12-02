require 'spec_helper'

describe InstitutionMetadata do
  before(:all) do 
    @i = Institution.new(pid: 'test:1234')
    @datastream = InstitutionMetadata.new(@i)
    @datastream.name = 'Test'
    @datastream.brief_name = 'tst'
    @datastream.identifier = 'test.org'
    @datastream.dpn_uuid = '1234'
  end

  it 'should retain properties' do
    @datastream.name.first.should == 'Test'
    @datastream.brief_name.first.should == 'tst'
    @datastream.identifier.first.should == 'test.org'
    @datastream.dpn_uuid.first.should == '1234'
  end

end