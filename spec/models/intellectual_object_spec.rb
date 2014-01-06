require 'spec_helper'
include Aptrust::SolrHelper

describe IntellectualObject do
  before(:all) do
    IntellectualObject.destroy_all
  end

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:institution) }
  it { should validate_presence_of(:rights)}

  describe "An instance" do
    it 'should have a descMetadata datastream' do
      subject.descMetadata.should be_kind_of IntellectualObjectMetadata
    end

    it 'should properly set a title' do
      subject.title = 'War and Peace'
      subject.title.should == 'War and Peace'
    end

    it 'should properly set rights' do
      subject.rights = 'public'
      subject.rights.should == 'public'
    end

    it 'must be one of the standard rights' do
      subject.rights = 'error'
      subject.should_not be_valid
    end

    it 'should properly set a description' do
      exp = Faker::Lorem.paragraph
      subject.description = exp
      subject.description.should == [exp]
    end

    it 'should properly set an identifier' do
      exp = SecureRandom.uuid
      subject.identifier = exp
      subject.identifier.should == [exp]
    end

    it "should have terms_for_editing" do
      expect(subject.terms_for_editing).to eq [:title, :description, :rights]
    end

    describe "#to_solr" do
      subject { FactoryGirl.build(:institutional_intellectual_object) }
      before do
        subject.generic_files << FactoryGirl.build(:generic_file, intellectual_object: subject)
        subject.generic_files << FactoryGirl.build(:generic_file, intellectual_object: subject)
      end      
      let(:solr_doc) { subject.to_solr }
      it "should have fields" do
        solr_doc['institution_name_ssi'].should == subject.institution.name 
        solr_doc['is_part_of_ssim'].should == subject.institution.internal_uri
        # Searchable
        solr_doc['desc_metadata__title_tesim'].should == [subject.title]
        # sortable
        solr_doc['desc_metadata__title_si'].should == subject.title
        solr_doc['desc_metadata__identifier_tesim'].should == subject.identifier
        solr_doc['desc_metadata__description_tesim'].should == subject.description
        solr_doc['desc_metadata__rights_sim'].should == ["institution"] 
        solr_doc['format_sim'].should == ["application/xml"] 
      end
    end
  end

  describe "A saved instance" do
    after { subject.destroy }

    describe "with generic files" do
      subject { FactoryGirl.create(:intellectual_object, generic_files: [FactoryGirl.create(:generic_file)]) }

      it 'should not be destroyable' do
        expect(subject.destroy).to be_false
      end
    end

    describe "indexes groups" do
      let(:inst_pid) { clean_for_solr(subject.institution.pid) }
      describe "with public access" do
        subject { FactoryGirl.create(:public_intellectual_object) }
        it 'should properly set groups' do
          expect(subject.edit_groups).to eq ["Admin_At_#{inst_pid}"]
          expect(subject.read_groups).to match_array ['institutional_user', 'institutional_admin']
          expect(subject.discover_groups).to eq []
        end
      end

      describe "with institutional access" do
        subject { FactoryGirl.create(:institutional_intellectual_object) }
        it 'should properly set groups' do
          expect(subject.edit_groups).to eq ["Admin_At_#{inst_pid}"]
          expect(subject.read_groups).to eq ["User_At_#{inst_pid}"]
          expect(subject.discover_groups).to eq []
        end
      end

      describe "with private access" do
        subject { FactoryGirl.create(:private_intellectual_object) }
        it 'should properly set groups' do
          expect(subject.edit_groups).to eq ["Admin_At_#{inst_pid}"]
          expect(subject.read_groups).to eq []
          expect(subject.discover_groups).to eq ["User_At_#{inst_pid}"]
        end
      end
    end
  end

end
