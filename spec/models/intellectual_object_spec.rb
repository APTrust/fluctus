# Generated via
#  `rails generate active_fedora::model IntellectualObject`
require 'spec_helper'
require 'active_fedora/test_support'
include Aptrust::SolrHelper

describe IntellectualObject do


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
  end

  describe "A saved instance" do
    subject { FactoryGirl.create(:intellectual_object) }
    let(:inst_pid) { clean_for_solr(subject.institution.pid) }
    after { subject.destroy }

    it 'must check for generic_files before destory' do
      item = FactoryGirl.create(:generic_file, intellectual_object: subject)
      subject.destroy.should be_false
      item.destroy
    end

    describe "with public access" do
      subject { FactoryGirl.create(:public_intellectual_object) }
      it 'should properly set groups' do
        expect(subject.edit_groups).to match_array ['admin', "Admin_At_#{inst_pid}"]
        expect(subject.read_groups).to match_array ['institutional_user', 'institutional_admin']
        expect(subject.discover_groups).to eq []
      end
    end

    describe "with institutional access" do
      subject { FactoryGirl.create(:institutional_intellectual_object) }
      it 'should properly set groups' do
        expect(subject.edit_groups).to match_array ['admin', "Admin_At_#{inst_pid}"]
        expect(subject.read_groups).to eq ["User_At_#{inst_pid}"]
        expect(subject.discover_groups).to eq []
      end
    end

    describe "with private access" do
      subject { FactoryGirl.create(:private_intellectual_object) }
      it 'should properly set groups' do
        expect(subject.edit_groups).to match_array ['admin', "Admin_At_#{inst_pid}"]
        expect(subject.read_groups).to eq []
        expect(subject.discover_groups).to eq ["User_At_#{inst_pid}"]
      end
    end
  end

end
