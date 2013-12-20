require 'spec_helper'

describe Institution do
  let (:i) { FactoryGirl.create(:institution) }

  after do
    i.destroy
  end

  it { should validate_presence_of(:name) }

  it 'should retun a proper solr_doc' do
    i.to_solr['desc_metadata__name_tesim'].should == [i.name]
  end

  describe "#users" do
    let!(:user) { FactoryGirl.create(:user, institution_pid: i.pid)  }

    it "should contain the appropriate User" do
      i.users.should eq [user]
    end

    it 'should return users sorted by name' do
      user1 = FactoryGirl.create(:user, name: "Zeke", institution_pid: i.pid) 
      user2 =  FactoryGirl.create(:user, name: "Andrew", institution_pid: i.pid) 
      i.users.index(user1).should > i.users.index(user2)
    end
  end

  describe "#name_is_unique" do
    it { should validate_uniqueness_of(:name) }
  end

  describe "deleting should be blocked" do 
    it 'if a user is associated' do 
      user = FactoryGirl.create(:user, institution_pid: i.pid)
      i.destroy.should be_false
      expect(Institution.exists?(i.pid)).to be_true
    end

    it 'if an intellectual object is associated' do
      item = FactoryGirl.create(:intellectual_object, institution: i)
      i.destroy.should be_false
      expect(Institution.exists?(i.pid)).to be_true
      item.destroy
    end
  end
end
