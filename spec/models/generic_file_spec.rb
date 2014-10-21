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

    let(:institution) { mock_model Institution, internal_uri: 'info:fedora/testing:123', name: 'Mock Name' }
    let(:intellectual_object) { mock_model IntellectualObject, institution: institution, identifier: 'info:fedora/testing:123/1234567' }

    describe "#to_solr" do
      let(:solr_doc) { subject.to_solr }
      it "should index the institution, so we can do aggregations without a join query" do
        solr_doc['institution_uri_ssim'].should == ['info:fedora/testing:123']
        solr_doc['gf_institution_name_ssim'].should == ['Mock Name']
        solr_doc['gf_parent_ssim'].should == ['info:fedora/testing:123/1234567']
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
        before do
          subject.save!
          @parent_processed_item = FactoryGirl.create(:processed_item,
                                                     object_identifier: subject.intellectual_object.identifier,
                                                     action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'],
                                                     stage: Fluctus::Application::FLUCTUS_STAGES['record'],
                                                     status: Fluctus::Application::FLUCTUS_STATUSES['success'])
        end
        after do
          subject.destroy
          intellectual_object.destroy
          @parent_processed_item.delete
        end

        let(:async_job) { double('one') }

        it "should set the state to deleted and index the object state" do
          expect {
            subject.soft_delete({type: 'delete', outcome_detail: "joe@example.com"})
          }.to change { subject.premisEvents.events.count}.by(1)
          expect(subject.state).to eq 'D'
          expect(subject.to_solr['object_state_ssi']).to eq 'D'
        end

        it "should create a ProcessedItem showing delete was requested" do
          subject.soft_delete({type: 'delete', outcome_detail: "user@example.com"})
          pi = ProcessedItem.where(generic_file_identifier: subject.identifier).first
          expect(pi).not_to be_nil
          expect(pi.object_identifier).to eq subject.intellectual_object.identifier
          expect(pi.action).to eq Fluctus::Application::FLUCTUS_ACTIONS['delete']
          expect(pi.stage).to eq Fluctus::Application::FLUCTUS_STAGES['requested']
          expect(pi.status).to eq Fluctus::Application::FLUCTUS_STATUSES['pend']
          expect(pi.user).to eq "user@example.com"
        end

      end

      describe "serializable_hash" do
        before do
        end
        after do
        end

        it "should set the state to deleted and index the object state" do
          h1 = subject.serializable_hash
          h1.has_key?(:id)
          h1.has_key?(:uri)
          h1.has_key?(:size)
          h1.has_key?(:created)
          h1.has_key?(:modified)
          h1.has_key?(:file_format)
          h1.has_key?(:identifier)
          h1.has_key?(:state)

          h2 = subject.serializable_hash(include: [:checksum, :premisEvents])
          h2.has_key?(:id)
          h2.has_key?(:uri)
          h2.has_key?(:size)
          h2.has_key?(:created)
          h2.has_key?(:modified)
          h2.has_key?(:file_format)
          h2.has_key?(:identifier)
          h2.has_key?(:state)
          h2.has_key?(:checksum)
          h2.has_key?(:premisEvents)
        end
      end

    end
  end
end
