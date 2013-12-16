require 'spec_helper'

describe User do
  let(:user) { FactoryGirl.create(:aptrust_user) }
  let(:admin_user) { FactoryGirl.create(:user, :admin) }
  let(:inst_admin) { FactoryGirl.create(:user, :institutional_admin) }
  let(:inst_user) { FactoryGirl.create(:user, :institutional_user) }

  after do
    user.destroy
  end

  describe "#where method works using RDF indexing uniqueness" do 
    it 'should return a valid institution' do
      user.institution.should == Institution.where(pid: user.institution.pid).first
    end

    it 'should return correct permission groups as an admin' do
      admin_user.groups.should == %w(admin)
    end

    it 'should return correct permission group as an institutional admin' do
      inst_admin.groups.include?('institutional_admin')
    end

    it 'should return correct institution group as an institutional admin' do
      inst_admin.groups.include?("Admin_At_#{user.institution_pid}")
    end

    it 'should return correct permission groups as an institutional user' do
      inst_user.groups.include?('institutional_user')
    end

    it 'should return correct institution group as an institutional user' do
      inst_user.groups.include?("User_At_#{user.institution_pid}")
    end

  end
end