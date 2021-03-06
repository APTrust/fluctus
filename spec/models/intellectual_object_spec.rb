require 'spec_helper'
include Aptrust::SolrHelper

describe IntellectualObject do
  before(:all) do
    IntellectualObject.destroy_all
  end

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:institution) }
  it { should validate_presence_of(:access)}

  describe 'An instance' do
    it 'should have a descMetadata datastream' do
      subject.descMetadata.should be_kind_of IntellectualObjectMetadata
    end

    it 'should have a premisEvents datastream' do
      subject.premisEvents.should be_kind_of PremisEventsMetadata
    end

    it 'should properly set a title' do
      subject.title = 'War and Peace'
      subject.title.should == 'War and Peace'
    end

    it 'should properly set access' do
      subject.access = 'consortia'
      subject.access.should == 'consortia'
    end

    it 'must be one of the standard access' do
      subject.access = 'error'
      subject.should_not be_valid
    end

    it 'should properly set a description' do
      exp = Faker::Lorem.paragraph
      subject.description = exp
      subject.description.should == exp
    end

    it 'should properly set an identifier' do
      exp = SecureRandom.uuid
      subject.identifier = exp
      subject.identifier.should == exp
    end

    it 'should properly set an alternative identifier' do
      exp = 'test.edu/123456'
      subject.alt_identifier = exp
      subject.alt_identifier.should == [exp]
    end

    it 'should properly set a bag name' do
      exp = 'bag_name'
      subject.bag_name = exp
      subject.bag_name.should == exp
    end

    it 'should have terms_for_editing' do
      expect(subject.terms_for_editing).to eq [:title, :description, :access]
    end

    describe '#to_solr' do
      subject { FactoryGirl.create(:institutional_intellectual_object) }
      before do
        subject.generic_files << FactoryGirl.build(:generic_file, intellectual_object: subject, size: 53)
        subject.generic_files << FactoryGirl.build(:generic_file, intellectual_object: subject, size: 47)
      end
      let(:solr_doc) { subject.to_solr }
      it 'should have fields' do
        solr_doc['institution_name_ssi'].should == subject.institution.name
        solr_doc['is_part_of_ssim'].should == subject.institution.internal_uri
        # Searchable
        solr_doc['desc_metadata__title_tesim'].should == [subject.title]
        # sortable
        solr_doc['desc_metadata__title_si'].should == subject.title
        solr_doc['desc_metadata__identifier_tesim'].should == [subject.identifier]
        solr_doc['desc_metadata__description_tesim'].should == [subject.description]
        solr_doc['desc_metadata__access_sim'].should == ['institution']
      end
    end
  end

  describe 'bytes_by_format' do
    subject { FactoryGirl.create(:institutional_intellectual_object) }
    it 'should return a hash' do
      expect(subject.bytes_by_format).to eq({"all"=>0})
    end

    describe 'with attached files' do
      before do
        subject.generic_files << FactoryGirl.build(:generic_file, intellectual_object: subject, size: 166311750, identifier: 'test.edu/123/data/file.xml')
        subject.generic_files << FactoryGirl.build(:generic_file, intellectual_object: subject, file_format: 'audio/wav', size: 143732461, identifier: 'test.edu/123/data/file.wav')
        subject.save!
      end

      it 'should return a hash' do
        expect(subject.bytes_by_format).to eq({"all"=>310044211,
                                               'application/xml' => 166311750,
                                               'audio/wav' => 143732461})
      end
    end
  end

  describe '#get_from_solr' do
    subject { FactoryGirl.create(:intellectual_object) }
    it 'should grab the object from solr and create an intellectual object for the data' do
      object = IntellectualObject.get_from_solr(subject.id)
      object.identifier.should == subject.identifier
      object.bag_name.should == subject.bag_name
      object.description.should == subject.description
      object.title.should == subject.title
      object.access.should == subject.access
    end
  end

  describe '#files_from_solr' do
    subject { FactoryGirl.create(:intellectual_object) }
    it 'should grab the objects files from solr and create generic file objects for them' do
      gf = FactoryGirl.build(:generic_file, intellectual_object: subject, size: 53)
      subject.generic_files << gf
      files = IntellectualObject.files_from_solr(subject.id)
      files[0].identifier.should == gf.identifier
    end
  end

  describe 'A saved instance' do
    after { subject.destroy }

    describe 'with generic files' do
      after do
        subject.generic_files.destroy_all
      end

      subject { FactoryGirl.create(:intellectual_object, bag_name: '') }

      before do
        @file = FactoryGirl.create(:generic_file, intellectual_object_id: subject.id)
        subject.reload
      end

      it 'test setup assumptions' do
        subject.id.should == subject.generic_files.first.intellectual_object_id
        subject.generic_files.should == [@file]
      end

      it 'should not be destroyable' do
        expect(subject.destroy).to be false
      end

      it 'should fill in an empty bag name with data from the identifier' do
        expect(subject.bag_name).to eq subject.identifier.split('/')[1]
      end

      describe 'soft_delete' do
        before {
          @processed_item = FactoryGirl.create(:processed_item,
                                               object_identifier: subject.identifier,
                                               action: Fluctus::Application::FLUCTUS_ACTIONS['ingest'],
                                               stage: Fluctus::Application::FLUCTUS_STAGES['record'],
                                               status: Fluctus::Application::FLUCTUS_STATUSES['success'])
        }
        after {
          @processed_item.delete
        }
        let(:intellectual_object_delete_job) { double('intellectual object') }
        let(:generic_file_delete_job) { double('file') }

        it 'should set the state to deleted and index the object state' do
          expect {
            subject.soft_delete({type: 'delete', outcome_detail: 'joe@example.com'})
          }.to change { subject.premisEvents.events.count}.by(1)
          subject.background_deletion({type: 'delete', outcome_detail: 'joe@example.com'})
          expect(subject.state).to eq 'D'
          expect(subject.to_solr['object_state_ssi']).to eq 'D'
          subject.generic_files.all?{ |file| expect(file.state).to eq 'D' }
        end

        it 'should set the state to deleted and index the object state' do
          subject.soft_delete({type: 'delete', outcome_detail: 'user@example.com'})
          subject.background_deletion({type: 'delete', outcome_detail: 'user@example.com'})
          subject.generic_files.all?{ |file|
            pi = ProcessedItem.where(generic_file_identifier: file.identifier).first
            expect(pi).not_to be_nil
            expect(pi.object_identifier).to eq subject.identifier
            expect(pi.action).to eq Fluctus::Application::FLUCTUS_ACTIONS['delete']
            expect(pi.stage).to eq Fluctus::Application::FLUCTUS_STAGES['requested']
            expect(pi.status).to eq Fluctus::Application::FLUCTUS_STATUSES['pend']
            expect(pi.user).to eq 'user@example.com'
          }
        end

      end
    end

    describe 'indexes groups' do
      let(:inst_pid) { clean_for_solr(subject.institution.pid) }
      describe 'with consortial access' do
        subject { FactoryGirl.create(:consortial_intellectual_object) }
        it 'should properly set groups' do
          expect(subject.edit_groups).to eq ["Admin_At_#{inst_pid}"]
          expect(subject.read_groups).to match_array %w(institutional_user institutional_admin)
          expect(subject.discover_groups).to eq []
        end
      end

      describe 'with institutional access' do
        subject { FactoryGirl.create(:institutional_intellectual_object) }
        it 'should properly set groups' do
          expect(subject.edit_groups).to eq ["Admin_At_#{inst_pid}"]
          expect(subject.read_groups).to eq ["User_At_#{inst_pid}"]
          expect(subject.discover_groups).to eq []
        end
      end

      describe 'with restricted access' do
        subject { FactoryGirl.create(:restricted_intellectual_object) }
        it 'should properly set groups' do
          expect(subject.edit_groups).to eq ["Admin_At_#{inst_pid}"]
          expect(subject.read_groups).to eq []
          expect(subject.discover_groups).to eq ["User_At_#{inst_pid}"]
        end
      end

      describe '#identifier_is_unique' do
        it 'should validate uniqueness of the identifier' do
          one = FactoryGirl.create(:intellectual_object, identifier: 'test.edu/234')
          two = FactoryGirl.build(:intellectual_object, identifier: 'test.edu/234')
          two.should_not be_valid
          two.errors[:identifier].should include('has already been taken')
        end
      end
    end
  end

end
