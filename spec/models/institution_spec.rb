require 'spec_helper'

describe Institution do
  subject { FactoryGirl.build(:institution) }

  it { should validate_presence_of(:name) }

  it 'should retun a proper solr_doc' do
    subject.to_solr['desc_metadata__name_tesim'].should == [subject.name]
  end

  describe "#name_is_unique" do
    it { should validate_uniqueness_of(:name) }
  end

  describe "bytes_by_format" do
    it "should return a hash" do
      expect(subject.bytes_by_format).to eq({"Total content upload"=>0})
    end
    describe 'with attached files' do
      before do
        subject.save!
      end
      let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: subject) }
      let!(:generic_file1) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object, size: '166311750.0') }
      let!(:generic_file2) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object, format: 'audio/wav', size: '143732461.0' ) }
      it "should return a hash" do
        expect(subject.bytes_by_format).to eq({"Total content upload"=>310044211.0,
                                               'application/xml' => 166311750,
                                               'audio/wav' => 143732461.0})
      end
    end
  end

  describe "a saved instance" do
    before do 
      subject.save
    end

    after do
      subject.destroy
    end
    describe "with an associated user" do
      let!(:user) { FactoryGirl.create(:user, name: "Zeke", institution_pid: subject.pid)  }

      it "should contain the appropriate User" do
        subject.users.should eq [user]
      end

      it 'deleting should be blocked' do 
        subject.destroy.should be_false
        expect(Institution.exists?(subject.pid)).to be_true
      end

      describe "or two" do
        let!(:user2) { FactoryGirl.create(:user, name: "Andrew", institution_pid: subject.pid) }
        it 'should return users sorted by name' do
          subject.users.index(user).should > subject.users.index(user2)
        end
      end
    end

    describe "with an associated intellectual object" do
      let!(:item) { FactoryGirl.create(:intellectual_object, institution: subject) }
      after { item.destroy }
      it 'deleting should be blocked' do
        subject.destroy.should be_false
        expect(Institution.exists?(subject.pid)).to be_true
      end
    end

  end
end
