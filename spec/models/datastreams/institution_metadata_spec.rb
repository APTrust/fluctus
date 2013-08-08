require 'spec_helper'

describe Datastream::InstitutionMetadata do 
  it "should return triples" do
    i = FactoryGirl.build(:aptrust)
    i.descMetadata.serialize == "<info:fedora/__DO_NOT_USE__> <http://purl.org/dc/terms/title> \"APTrust\" .\n"
  end
end