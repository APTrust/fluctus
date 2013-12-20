require 'spec_helper'
include Aptrust::SolrHelper

describe User do
  let(:user) { FactoryGirl.create(:aptrust_user) }
  let(:inst_admin) { FactoryGirl.create(:user, :institutional_admin) }
  let(:inst_pid) { clean_for_solr(subject.institution_pid) }

  it 'should return a valid institution' do
    user.institution.pid.should == user.institution_pid
  end

  describe "as an admin" do
    subject { FactoryGirl.create(:user, :admin) }
    its(:groups) { should match_array %w(registered admin) }
  end
  describe "as an institutional admin" do
    subject { FactoryGirl.create(:user, :institutional_admin) }
    its(:groups) { should match_array ['registered', 'institutional_admin', "Admin_At_#{inst_pid}"]}
  end
  describe "as an institutional user" do
    subject { FactoryGirl.create(:user, :institutional_user) }
    its(:groups) { should match_array ['registered', 'institutional_user', "User_At_#{inst_pid}"]}
  end

end
