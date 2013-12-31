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
  it { should validate_presence_of(:checksum) }

  it 'should copy the permissions of the intellectual object it belongs to' do
    int_obj = FactoryGirl.create(:intellectual_object)
    #int_obj.set_permissions
    gen_file = FactoryGirl.create(:generic_file, intellectual_object: int_obj)
    gen_file.set_permissions
    (int_obj.discover_groups.should == gen_file.discover_groups) &&
        (int_obj.read_groups.should == gen_file.read_groups) &&
        (int_obj.edit_groups.should == gen_file.edit_groups)
    #gen_file.permissions.should == int_obj.permissions
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
