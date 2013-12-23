class UsersController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!

  def destroy
    name = @user.to_s
    destroy!(notice: "User #{@user.to_s} was deleted.")
  end

  private

    def build_resource_params
      [params.fetch(:user, {}).permit(:name, :email, :phone_number).tap do |p|
        if params[:user][:institution_pid]
          institution = Institution.find(params[:user][:institution_pid])
          authorize!(:add_user, institution)
          p[:institution_pid] = institution.id
        end
        if params[:user][:role_ids]
          roles = Role.find(params[:user][:role_ids])
          roles.each do |role|
            authorize!(:add_user, role)
            p[:role_ids] ||= []
            p[:role_ids] << role.id
          end
        end
      end]
    end
end
