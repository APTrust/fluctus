class UsersController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  before_filter :authenticate_user!

  def destroy
    name = @user.to_s
    destroy!(notice: "User #{@user.to_s} was deleted.")
  end

  private

    def build_resource_params
      [params.fetch(:user, {}).permit(:name, :email, :phone_number).tap do |p|
        p[:institution_pid] = build_institution_pid if params[:user][:institution_pid]
        p[:role_ids] = build_role_ids if params[:user][:role_ids]
      end]
    end

    def build_institution_pid
      institution = Institution.find(params[:user][:institution_pid])
      authorize!(:add_user, institution)
      institution.id
    end

    def build_role_ids
      [].tap do |role_ids|
        roles = Role.find(params[:user][:role_ids].reject &:blank?)
        roles.each do |role|
          authorize!(:add_user, role)
          role_ids << role.id
        end
      end
    end
end
