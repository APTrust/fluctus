require 'spec_helper'

describe RolePolicy do

  let(:institution) { FactoryGirl.create(:institution) }
  let!(:admin) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid )}
  let!(:inst_admin) { FactoryGirl.create(:user, :institutional_admin, institution_pid: institution.pid )}
  let!(:inst_user) { FactoryGirl.create(:user, :institutional_user, institution_pid: institution.pid )}

  context "for an admin user" do
    
    subject (:role_policy) { RolePolicy.new(admin, Role.where(name: 'admin').first) }
    it { should permit(:add_user) }

    subject (:role_policy) { RolePolicy.new(admin, Role.where(name: 'institutional_admin').first) }
    it { should permit(:add_user) }

    subject (:role_policy) { RolePolicy.new(admin, Role.where(name: 'institutional_user').first) }
    it { should permit(:add_user) }
  end

  context "for an institutional admin user" do
    
    subject (:role_policy) { RolePolicy.new(inst_admin, Role.where(name: 'admin').first) }
    it { should_not permit(:add_user) }

    subject (:role_policy) { RolePolicy.new(inst_admin, Role.where(name: 'institutional_admin').first) }
    it { should permit(:add_user) }

    subject (:role_policy) { RolePolicy.new(inst_admin, Role.where(name: 'institutional_user').first) }
    it { should permit(:add_user) }
  end

  context "for an institutional user" do

    subject (:role_policy) { RolePolicy.new(inst_user, Role.where(name: 'admin').first) }
    it { should_not permit(:add_user) }

    subject (:role_policy) { RolePolicy.new(inst_user, Role.where(name: 'institutional_admin').first) }
    it { should_not permit(:add_user) }

    subject (:role_policy) { RolePolicy.new(inst_user, Role.where(name: 'institutional_user').first) }
    it { should_not permit(:add_user) }
  end
  
  context "for an authenticated user without a user group" do
    let(:user) { FactoryGirl.create(:user) }
    subject (:role_policy) { RolePolicy.new(user, Role.where(name: 'admin').first) }
    it { should_not permit(:add_user) }

    subject (:role_policy) { RolePolicy.new(user, Role.where(name: 'institutional_admin').first) }
    it { should_not permit(:add_user) }

    subject (:role_policy) { RolePolicy.new(user, Role.where(name: 'institutional_user').first) }
    it { should_not permit(:add_user) }
  end 
end