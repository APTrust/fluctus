require 'spec_helper'

describe GenericFileMetadata do

  before do
    subject.stub(:pid).and_return("fake:123")
  end

  it 'should set a a proper format' do
    subject.format = 'application/pdf'
    subject.format.should ==  ['application/pdf']
  end

  it 'should set uri attributes' do
    uri = "baguri/data/#{Faker::Lorem.characters(char_count=rand(3..10))}.pdf"
    subject.uri = uri
    subject.uri.should == [uri]
  end

  it 'should set an identifier' do
    ident = "test.edu/12345678/data/filename.xml"
    subject.identifier = ident
    subject.identifier.should == [ident]
  end

  it 'should set size attributes' do
    sz = rand(2000...50000000000)
    subject.size = sz
    subject.size.should == [sz]
  end

  it 'should set created attributes' do
    dt = Time.now
    subject.created = dt.to_s
    subject.created.should == [dt.to_s]
  end

  it 'should set modified attributes' do
    dt = Time.now
    subject.modified = dt.to_s
    subject.modified.should == [dt.to_s]
  end

  it 'should set a proper nested checksum attribute' do
    exp = {
        algorithm: 'md5',
        datetime: Time.now.to_s,
        digest: SecureRandom.hex
    }
    subject.checksum_attributes = [exp]
    subject.checksum.last.algorithm.should == [exp[:algorithm]]
    subject.checksum.last.datetime.should == [exp[:datetime]]
    subject.checksum.last.digest.should == [exp[:digest]]
  end

  describe "#to_solr" do
    subject { FactoryGirl.build(:generic_file, size: 128774003000 ).to_solr }
    it "should have size indexed as a long" do
      expect(subject['tech_metadata__size_lsi']).to eq '128774003000'
    end
    it "should have mime type indexed " do
      expect(subject['tech_metadata__format_ssi']).to eq "application/xml"
    end
  end
end
