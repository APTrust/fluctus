# Generated via
#  `rails generate active_fedora::model IntellectualObject`
require 'spec_helper'
require 'active_fedora/test_support'
include Aptrust::SolrHelper

describe IntellectualObject do

  let(:subject) { FactoryGirl.create(:intellectual_object) }
  let(:public_subject) { FactoryGirl.create(:public_intellectual_object) }
  let(:inst_subject) { FactoryGirl.create(:institutional_intellectual_object) }
  let(:private_subject) { FactoryGirl.create(:private_intellectual_object) }

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:institution) }
  it { should validate_presence_of(:rights)}

  it 'should have a descMetadata datastream' do
    subject.descMetadata.should be_kind_of IntellectualObjectMetadata
  end

  it 'should properly set a title' do
    subject.title = 'War and Peace'
    subject.title.should == 'War and Peace'
  end

  it 'should properly set rights' do
    subject.rights = 'public'
    subject.rights.should == 'public'
  end

  it 'must be one of the standard rights' do
    subject.rights = 'error'
    subject.should_not be_valid
  end

  it 'should properly set a description' do
    exp = Faker::Lorem.paragraph
    subject.description = exp
    subject.description.should == [exp]
  end

  it 'should properly set an identifier' do
    exp = SecureRandom.uuid
    subject.identifier = exp
    subject.identifier.should == [exp]
  end

  it 'must check for generic_files before destory' do
    item = FactoryGirl.create(:generic_file, intellectual_object: subject)
    subject.destroy.should be_false
    item.destroy
  end

  it 'should properly set discover groups if rights are public' do
    #public_subject.set_permissions
    (public_subject.discover_groups.include?('admin') ) &&
        (public_subject.discover_groups.include?('institutional_admin')) &&
        (public_subject.discover_groups.include?('institutional_user'))
  end

  it 'should properly set read groups if rights are public' do
    #public_subject.set_permissions
    (public_subject.read_groups.include?('admin') ) &&
        (public_subject.read_groups.include?('institutional_admin')) &&
        (public_subject.read_groups.include?('institutional_user'))
  end

  it 'should properly set edit groups if rights are public' do
    #public_subject.set_permissions
    inst_pid = clean_for_solr(public_subject.institution.pid)
    (public_subject.edit_groups.include?('admin') ) &&
        (public_subject.edit_groups.include?("Admin_At_#{inst_pid}"))
  end

  it 'should properly set discover groups if rights are institutional' do
    #inst_subject.set_permissions
    inst_pid = clean_for_solr(inst_subject.institution.pid)
    (inst_subject.discover_groups.include?('admin') ) &&
        (inst_subject.discover_groups.include?("Admin_At_#{inst_pid}")) &&
        (inst_subject.discover_groups.include?("User_At_#{inst_pid}"))
  end

  it 'should properly set read groups if rights are institutional' do
    #inst_subject.set_permissions
    inst_pid = clean_for_solr(inst_subject.institution.pid)
    (inst_subject.read_groups.include?('admin') ) &&
        (inst_subject.read_groups.include?("Admin_At_#{inst_pid}")) &&
        (inst_subject.read_groups.include?("User_At_#{inst_pid}"))
  end

  it 'should properly set edit groups if rights are institutional' do
    #inst_subject.set_permissions
    inst_pid = clean_for_solr(inst_subject.institution.pid)
    (inst_subject.edit_groups.include?('admin') ) &&
        (inst_subject.edit_groups.include?("Admin_At_#{inst_pid}"))
  end

  it 'should properly set discover groups if rights are private' do
    #private_subject.set_permissions
    inst_pid = clean_for_solr(private_subject.institution.pid)
    (private_subject.discover_groups.include?('admin') ) &&
        (private_subject.discover_groups.include?("Admin_At_#{inst_pid}")) &&
        (private_subject.discover_groups.include?("User_At_#{inst_pid}"))
  end

  it 'should properly set read groups if rights are private' do
    #private_subject.set_permissions
    inst_pid = clean_for_solr(private_subject.institution.pid)
    (private_subject.read_groups.include?('admin') ) &&
        (private_subject.read_groups.include?("Admin_At_#{inst_pid}")) &&
        (private_subject.read_groups.include?("User_At_#{inst_pid}"))
  end

  it 'should properly set edit groups if rights are private' do
    #private_subject.set_permissions
    inst_pid = clean_for_solr(private_subject.institution.pid)
    (private_subject.edit_groups.include?('admin') ) &&
        (private_subject.edit_groups.include?("Admin_At_#{inst_pid}"))
  end

end
