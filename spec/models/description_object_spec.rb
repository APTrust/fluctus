require 'spec_helper'

describe DescriptionObject do
  let(:i) { FactoryGirl.create(:institution) }
  let(:desc) { FactoryGirl.create(:description_object, institution: i) }

  after do
    desc.destroy unless desc.new_record?
    i.destroy unless i.new_record?
  end

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:institution) }

  it 'should serialize descMetadata as RDF triples' do 
    desc.descMetadata.serialize.should == "<info:fedora/#{desc.pid}> <http://purl.org/dc/terms/title> \"#{desc.title}\" .\n"
  end
end