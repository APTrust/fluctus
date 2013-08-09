require 'spec_helper'

describe User do
  before do
   @aptrust = FactoryGirl.create(:aptrust)
   @outside_institution = FactoryGirl.create(:fake_university)
  end

  let(:user) { FactoryGirl.create(:aptrust_user) }

  after do
    @aptrust.delete
    @outside_institution.delete
    user.delete
  end

  describe "#where method works using RDF indexing uniqueness" do 
    it 'should retrun a valid institution' do 
      user.institution.should == @aptrust
    end
  end
end