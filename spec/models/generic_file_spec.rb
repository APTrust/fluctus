require 'spec_helper'

describe GenericFile do

  it 'uses the Auditable module to create premis events' do
    GenericFile.included_modules.include?(Auditable).should be_true
    subject.respond_to?(:add_event).should be_true
  end

  it 'should have a techMetadata datastream' do
    subject.techMetadata.should be_kind_of GenericFileMetadata
  end

  it 'should have a premisEvents datastream' do
    subject.premisEvents.should be_kind_of PremisEventsMetadata
  end

  it 'delegates institution to the intellectual object' do
    file = FactoryGirl.create(:generic_file)
    institution = file.intellectual_object.institution
    file.institution.should == institution
  end

  it { should validate_presence_of(:uri) }
  it { should validate_presence_of(:size) }
  it { should validate_presence_of(:created) }
  it { should validate_presence_of(:modified) }
  it { should validate_presence_of(:file_format) }
  it { should validate_presence_of(:identifier)}
  it "should validate presence of a checksum" do
    expect(subject.valid?).to be_false
    expect(subject.errors[:checksum]).to eq ["can't be blank"]
    subject.checksum_attributes = [{digest: '1234'}]
    # other fields cause the object to not be valid. This forces recalculating errors
    expect(subject.valid?).to be_false
    expect(subject.errors[:checksum]).to be_empty
  end

  describe "#identifier_is_unique" do
    it "should validate uniqueness of the identifier" do
      one = FactoryGirl.create(:generic_file, identifier: "test.edu")
      two = FactoryGirl.build(:generic_file, identifier: "test.edu")
      two.should_not be_valid
      two.errors[:identifier].should include("has already been taken")
    end
  end

  describe "with an intellectual object" do
    before do
      subject.intellectual_object = intellectual_object
    end

    let(:institution) { mock_model Institution, internal_uri: 'info:fedora/testing:123' }
    let(:intellectual_object) { mock_model IntellectualObject, institution: institution }

    describe "#to_solr" do
      let(:solr_doc) { subject.to_solr }
      it "should index the institution, so we can do aggregations without a join query" do
        solr_doc['institution_uri_ssim'].should == ['info:fedora/testing:123']
      end
    end

    describe 'that is saved' do
      let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
      subject { FactoryGirl.build(:generic_file, intellectual_object: intellectual_object) }
      describe "permissions" do
        before do
          intellectual_object.permissions = [
            Hydra::AccessControls::Permission.new(:name=>"institutional_admin", :access=>"read", :type=>"group"),
            Hydra::AccessControls::Permission.new(:name=>"institutional_user", :access=>"read", :type=>"group"),
            Hydra::AccessControls::Permission.new(:name=>"Admin_At_aptrust-test_22953", :access=>"edit", :type=>"group")]
        end
        after do
          subject.destroy
          intellectual_object.destroy
        end
        it 'should copy the permissions of the intellectual object it belongs to' do
          subject.save!
          subject.permissions.should == [
            Hydra::AccessControls::Permission.new(:name=>"institutional_admin", :access=>"read", :type=>"group"),
            Hydra::AccessControls::Permission.new(:name=>"institutional_user", :access=>"read", :type=>"group"),
            Hydra::AccessControls::Permission.new(:name=>"Admin_At_aptrust-test_22953", :access=>"edit", :type=>"group")]
        end
      end
      describe "its intellectual_object" do
        after(:all)do # Must use after(:all) to avoid 'can't modify frozen Class' bug in rspec-mocks
          subject.destroy
          intellectual_object.destroy
        end

        # TURNED OFF BY A.D. 7/7/2014 BECAUSE SYSTEM IS UNUSABLE IN PRODUCTION WITH REINDEXING ON!
        #it "should reindex" do
        #  intellectual_object.should_receive(:update_index)
        #  subject.save!
        #end
      end

      describe "soft_delete" do
        after do
          subject.destroy
          intellectual_object.destroy
        end
        before do
          subject.save!
        end

        let(:async_job) { double('one') }

        it "should set the state to deleted and index the object state" do
          DeleteGenericFileJob.should_receive(:new).with(subject.pid).and_return(async_job)
          OrderUp.should_receive(:push).with(async_job).once
          expect {
            subject.soft_delete
          }.to change { subject.premisEvents.events.count}.by(1)
          expect(subject.state).to eq 'D'
          expect(subject.to_solr['object_state_ssi']).to eq 'D'
        end
      end
    end
  end
end
