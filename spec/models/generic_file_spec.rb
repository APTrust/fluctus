require 'spec_helper'

describe GenericFile do

  it 'should have a descMetadata datastream' do
    subject.descMetadata.should be_kind_of GenericFileMetadata
  end

  it 'should have a premisEvents datastream' do
    subject.premisEvents.should be_kind_of PremisEventsMetadata
  end

  it { should validate_presence_of(:uri) }
  it { should validate_presence_of(:size) }
  it { should validate_presence_of(:created) }
  it { should validate_presence_of(:modified) }
  it { should validate_presence_of(:format) }
  it "should validate presence of checksum" do 
    expect(subject.valid?).to be_false
    expect(subject.errors[:checksum]).to eq ["can't be blank"]
    subject.checksum_attributes = [{digest: '1234'}]
    # other fields cause the object to not be valid. This forces recalculating errors
    expect(subject.valid?).to be_false
    expect(subject.errors[:checksum]).to be_empty
  end


  describe "permissions" do
    let(:int_obj) { FactoryGirl.create(:intellectual_object) }
    let(:gen_file) { FactoryGirl.create(:generic_file, intellectual_object: int_obj) }
    after do
      gen_file.destroy
      int_obj.destroy
    end
    it 'should copy the permissions of the intellectual object it belongs to' do
      gen_file.permissions.should == int_obj.permissions
    end
  end

  describe "#to_solr" do
    before do
      subject.intellectual_object = intellectual_object
    end
    let(:institution) { mock_model Institution, internal_uri: 'info:fedora/testing:123' }
    let(:intellectual_object) { mock_model IntellectualObject, institution: institution }
    let(:solr_doc) { subject.to_solr }
    it "should index the institution, so we can do aggregations without a join query" do
      solr_doc['institution_uri_ssim'].should == ['info:fedora/testing:123']
    end
  end

end
