# Generated via
#  `rails generate active_fedora::model IntellectualObject`
require 'spec_helper'

formats = [
    {ext: "txt", type: "plain/text"},
    {ext: "xml", type: "application/xml"},
    {ext: "xml", type: "application/rdf+xml"},
    {ext: "pdf", type: "application/pdf"},
    {ext: "tif", type: "image/tiff"},
    {ext: "mp4", type: "video/mp4"},
    {ext: "wav", type: "audio/wav"},
    {ext: "pdf", type: "application/pdf"}
]

describe GenericFileMetadata do

  before do
    @gf = FactoryGirl.create(:generic_file)
    @ds = @gf.descMetadata
  end

  it 'should set a a proper format' do
    formats.each do |fmt|
      @ds.format = fmt[:type]
      @ds.format.should ==  [fmt[:type]]
    end
  end

  it 'should set uri attributes' do
    formats.each do |fmt|
      uri = "baguri/data/#{Faker::Lorem.characters(char_count=rand(3..10))}.#{fmt[:ext]}"
      @ds.uri = uri
      @ds.uri.should == [uri]
    end
  end

  it 'should set size attributes' do
    sz = rand(2000...50000000000)
    @ds.size = sz
    @ds.size.should == [sz.to_s]
  end

  it 'should set created attributes' do
    dt = Time.now
    @ds.created = dt.to_s
    @ds.created.should == [dt.to_s]
  end

  it 'should set modified attributes' do
    dt = Time.now
    @ds.modified = dt.to_s
    @ds.modified.should == [dt.to_s]
  end

  it 'should set a proper nested checksum attribute' do
    exp = {
        algorithm: 'md5',
        datetime: Time.now.to_s,
        digest: SecureRandom.hex
    }
    @ds.checksum_attributes = [exp]
    @ds.checksum.last.algorithm.should == [exp[:algorithm]]
    @ds.checksum.last.datetime.should == [exp[:datetime]]
    @ds.checksum.last.digest.should == [exp[:digest]]
  end
end