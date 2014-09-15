=begin
require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  before :all do
    Institution.destroy_all
    @user_institution = FactoryGirl.create(:institution)
  end


  describe 'an admin user' do
    before (:all) {
      @intellectual_object = FactoryGirl.create(:intellectual_object)
    }

    let(:admin) { FactoryGirl.create(:user, :admin, institution_pid: @user_institution.pid) }
    let(:user) { FactoryGirl.create(:user, institution_pid: @user_institution.pid) }
    let(:intellectual_object) { @intellectual_object }
    subject { Ability.new(admin) }

    it { should be_able_to(:create, Institution) }
    it { should be_able_to(:edit, intellectual_object) }
    it { should be_able_to(:add_user, intellectual_object.institution) }
    it { should be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }
    it { should be_able_to(:add_user, Role.where(name: 'institutional_user').first) }

    it { should be_able_to(:generate_api_key, user) }
    it { should be_able_to(:generate_api_key, admin) }

    describe "with a file" do
      let(:file) { FactoryGirl.create(:generic_file) }
      it { should be_able_to(:update, file) }
      it { should be_able_to(:create, intellectual_object.generic_files.build) }
    end
  end

  describe 'an institutional_admin user' do
    before (:all) {
      @institutional_admin = FactoryGirl.create(:user, :institutional_admin, institution_pid: @user_institution.pid )
      @intellectual_object = FactoryGirl.create(:intellectual_object, institution: @user_institution)
    }
    let(:institutional_admin) { @institutional_admin }
    let(:intellectual_object) { @intellectual_object }

    subject { Ability.new(institutional_admin) }

    it { should     be_able_to(:edit, intellectual_object) }
    it { should     be_able_to(:update, SolrDocument.new(intellectual_object.rightsMetadata.to_solr.merge(id: intellectual_object.pid))) }
    it { should_not be_able_to(:edit, FactoryGirl.create(:intellectual_object)) }

    it { should_not be_able_to(:create, Institution) }
    it { should     be_able_to(:add_user, @user_institution) }
    it { should_not be_able_to(:add_user, FactoryGirl.create(:institution)) }
    it { should_not be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should     be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }
    it { should     be_able_to(:add_user, Role.where(name: 'institutional_user').first) }
    it { should     be_able_to(:generate_api_key, institutional_admin) }

    describe "when the user is" do
      describe "in my institution" do
        let(:user) { FactoryGirl.create(:user, institution_pid: @user_institution.pid) }
        it { should     be_able_to(:update, user) }
        it { should_not be_able_to(:generate_api_key, user) }
      end

      describe "not in my institution" do
        let(:user) { FactoryGirl.create(:user) }
        it { should_not be_able_to(:update, user) }
        it { should_not be_able_to(:assign_admin_user, user) }
        it { should_not be_able_to(:generate_api_key, user) }
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
    before (:all) {
      @institutional_user = FactoryGirl.create(:user, :institutional_user, institution_pid: @user_institution.pid )
      @intellectual_object = FactoryGirl.create(:intellectual_object, institution: @institutional_user.institution)
      @file = FactoryGirl.create(:generic_file, intellectual_object: @intellectual_object)
    }

    let(:institutional_user) { @institutional_user }
    let(:intellectual_object) { @intellectual_object }
    let(:file) { @file }

    subject { Ability.new(institutional_user) }

    it { should_not be_able_to(:edit, intellectual_object) }
    it { should_not be_able_to(:add_user, Role.where(name: 'admin').first) }
    it { should_not be_able_to(:add_user, Role.where(name: 'institutional_admin').first) }

    it { should_not be_able_to(:add_user, institutional_user.institution) }
    it { should_not be_able_to(:create, Institution) }
    it { should_not be_able_to(:update, User.new) }
    it { should     be_able_to(:update, institutional_user) }
    it { should     be_able_to(:generate_api_key, institutional_user) }
    it { should     be_able_to(:read,   institutional_user.institution) }
    it { should_not be_able_to(:read,   FactoryGirl.create(:institution)) }
    it { should_not be_able_to(:update, file) }

    describe "when the file is" do
      #@file = FactoryGirl.create(:generic_file, intellectual_object: intellectual_object)
      describe "in my institution" do
        it { should_not be_able_to(:update, @file) }
        it { should_not be_able_to(:create, @intellectual_object.generic_files.build) }
      end
    end

    describe "when the user is" do
      let(:user) { FactoryGirl.create(:user, institution_pid: @user_institution.pid) }

      describe "in my institution" do
        it { should_not be_able_to(:generate_api_key, user) }
      end
    end
  end
end
=end
