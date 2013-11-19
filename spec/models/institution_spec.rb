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
    before do
      @user =  FactoryGirl.create(:user, institution_pid: i.pid) 
    end

    it "should return an array of users" do 
      i.users.class.should == [].class
    end

    it "should contain the appropriate User" do
      i.users.should include(@user)
    end

    it 'should only contain one user' do 
      i.users.count.should == 1
    end

    it 'should return users sorted by name' do
      @user1 = FactoryGirl.create(:user, name: "Zeke", institution_pid: i.pid) 
      @user2 =  FactoryGirl.create(:user, name: "Andrew", institution_pid: i.pid) 
      i.users.index(@user1).should > i.users.index(@user2)
    end
  end

  describe '#where behavior when using RDF' do
    it 'should return a vailid Institution object' do 
      Institution.where(pid: i.pid).count.should == 1
    end
  end

  describe "#name_is_unique" do
    it { should validate_uniqueness_of(:name) }
  end

  describe "#check_for_association" do 
    it 'should not delete if a user is associated' do 
      user = FactoryGirl.create(:user, institution_pid: i.pid)
      i.destroy.should be_false
      user.destroy
    end

    it 'should not delete if a description object is associated' do
      description_object = FactoryGirl.create(:description_object, institution: i)
      i.destroy.should be_false
      description_object.destroy
    end
  end
end
