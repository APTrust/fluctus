require 'spec_helper'

describe User do
  let(:user) { FactoryGirl.create(:aptrust_user) }

  after do
    user.delete
  end

  describe "#where method works using RDF indexing uniqueness" do 
    it 'should retrun a valid institution' do 
      user.institution.should == Institution.where(desc_metadata__name_tesim: user.institution.name).first
    end
  end
end