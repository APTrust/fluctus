require 'spec_helper'
require 'cancan/matchers'

#TODO this could be made faster if we create the insitution for all the users just once (before :all)
describe Ability do
  before :all do
    Institution.destroy_all
  end
  describe 'an admin user' do
    let(:user) { FactoryGirl.create(:user) }
    let(:admin) { FactoryGirl.create(:user, :admin) }
    let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
    subject { Ability.new(admin) }

    it { should be_able_to(:create, Institution) }
    it { should be_able_to(:edit, intellectual_object) }
    it { should be_able_to(:add_user, FactoryGirl.create(:institution)) }
    it { should be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }
    it { should be_able_to(:add_user, Role.where(name: 'institutional_user').first) }

    describe "with a file" do
      let(:file) { FactoryGirl.create(:generic_file) }
      it { should be_able_to(:update, file) }
      it { should be_able_to(:create, intellectual_object.generic_files.build) }
    end
  end

  describe 'an institutional_admin user' do
    let(:institutional_admin) { FactoryGirl.create(:user, :institutional_admin) }
    let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: institutional_admin.institution) }
    subject { Ability.new(institutional_admin) }

    it { should     be_able_to(:edit, intellectual_object) }
    it { should_not be_able_to(:edit, FactoryGirl.create(:intellectual_object)) }

    it { should_not be_able_to(:create, Institution) }
    it { should     be_able_to(:add_user, institutional_admin.institution) }
    it { should_not be_able_to(:add_user, FactoryGirl.create(:institution)) }
    it { should_not be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should_not be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }
    it { should     be_able_to(:add_user, Role.where(name: 'institutional_user').first) }

    describe "when the user is" do
      describe "in my institution" do
        let(:user) { FactoryGirl.create(:user, institution_pid: institutional_admin.institution_pid) }
        it { should     be_able_to(:update, user) }
      end

      describe "not in my institution" do
        let(:user) { FactoryGirl.create(:user) }
        it { should_not be_able_to(:update, user) }
        it { should_not be_able_to(:assign_admin_user, user) }
      end
    end
    describe "when the file is" do
      let(:file) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object) }
      describe "in my institution" do
        it { should be_able_to(:update, file) }
        it { should be_able_to(:create, intellectual_object.generic_files.build) }
      end
      describe "not in my institution" do
        let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
        it { should_not be_able_to(:update, file) }
        it { should_not be_able_to(:create, intellectual_object.generic_files.build) }
      end
    end

    describe "when the object is" do
      describe "in my institution" do
        it { should be_able_to(:update, intellectual_object) }
        it { should be_able_to(:create, institutional_admin.institution.intellectual_objects.build) }
      end
      describe "not in my institution" do
        let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
        let(:institution) { FactoryGirl.create(:institution) }
        it { should_not be_able_to(:update, intellectual_object) }
        it { should_not be_able_to(:create, institution.intellectual_objects.build) }
      end
    end
  end

  describe 'an institutional_user' do
    let(:institutional_user) { FactoryGirl.create(:user, :institutional_user) }
    let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: institutional_user.institution) }
    let(:file) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object) }
    let(:user) { FactoryGirl.create(:user) }
    subject { Ability.new(institutional_user) }
    it { should_not be_able_to(:edit, intellectual_object) }
    it { should_not be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should_not be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }

    it { should_not be_able_to(:add_user, institutional_user.institution) }
    it { should_not be_able_to(:create, Institution) }
    it { should_not be_able_to(:update, user) }
    it { should     be_able_to(:update, institutional_user) }
    it { should     be_able_to(:read,   institutional_user.institution) }
    it { should_not be_able_to(:read,   user.institution) }
    it { should_not be_able_to(:update, file) }

    describe "when the file is" do
      let(:file) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object) }
      describe "in my institution" do
        it { should_not be_able_to(:update, file) }
        it { should_not be_able_to(:create, intellectual_object.generic_files.build) }
      end
    end
  end
end
