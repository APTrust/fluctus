require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  before :all do
    Institution.destroy_all
  end
  describe 'an admin user' do
    let(:user) { FactoryGirl.create(:user) }
    let(:admin) { FactoryGirl.create(:user, :admin) }
    subject { Ability.new(admin) }

    it { should be_able_to(:create, Institution) }
    it { should be_able_to(:assign_admin_user, user) }
    it { should be_able_to(:add_user, FactoryGirl.create(:institution)) }
    it { should be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }
    it { should be_able_to(:add_user, Role.where(name: 'institutional_user').first) }
  end

  describe 'an institutional_admin user' do
    let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin) }
    subject { Ability.new(institutional_admin) }

    it { should_not be_able_to(:create, Institution) }
    it { should     be_able_to(:add_user, institutional_admin.institution) }
    it { should_not be_able_to(:add_user, FactoryGirl.create(:institution)) }
    it { should_not be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should_not be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }
    it { should     be_able_to(:add_user, Role.where(name: 'institutional_user').first) }

    describe "when the user is in my institution" do
      let(:user) { FactoryGirl.create(:user, institution_pid: institutional_admin.institution_pid) }
      it { should     be_able_to(:update, user) }
      it { should_not be_able_to(:assign_admin_user, user) }
    end

    describe "when the user is not in my institution" do
      let(:user) { FactoryGirl.create(:user) }
      it { should_not be_able_to(:update, user) }
      it { should_not be_able_to(:assign_admin_user, user) }
    end
  end

  describe 'an institutional_user' do
    let(:institutional_user) { FactoryGirl.create(:user, :institutional_user) }
    let(:user) { FactoryGirl.create(:user) }
    subject { Ability.new(institutional_user) }
    it { should_not be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should_not be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }

    it { should_not be_able_to(:add_user, institutional_user.institution) }
    it { should_not be_able_to(:create, Institution) }
    it { should_not be_able_to(:update, user) }
    it { should     be_able_to(:update, institutional_user) }
    it { should     be_able_to(:read,   institutional_user.institution) }
    it { should_not be_able_to(:read,   user.institution) }
    it { should_not be_able_to(:assign_admin_user, user) }
  end
end
